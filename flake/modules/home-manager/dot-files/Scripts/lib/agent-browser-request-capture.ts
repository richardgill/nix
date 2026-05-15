import fs from "node:fs/promises";
import path from "node:path";

type BodyCapture = {
  encoding: "utf8" | "base64";
  bytes: number;
  text: string;
} | null;

type RequestRecord = {
  id: string;
  file: string;
  startedAt: string;
  request: {
    method: string;
    url: string;
    resourceType: string;
    headers: Record<string, string>;
    body: BodyCapture;
  };
  response: {
    receivedAt: string;
    status: number;
    statusText: string;
    headers: Record<string, string>;
    body: BodyCapture | { error: string } | null;
  } | null;
  failure: {
    failedAt: string;
    error: unknown;
  } | null;
};

type NetworkState = {
  runDir: string;
  records: Map<string, RequestRecord>;
  pendingWrites: Set<Promise<unknown>>;
  sequence: number;
};

type CdpClient = {
  ws: WebSocket;
  send: (method: string, params?: Record<string, unknown>) => Promise<any>;
};

const safeIso = (date = new Date()) => date.toISOString().replaceAll(":", "-");

const slugPart = (value: string) => value.replaceAll(/[^a-zA-Z0-9._-]+/g, "-").replaceAll(/^-|-$/g, "");

const slugUrl = (value: string) => {
  try {
    const url = new URL(value);
    const host = slugPart(url.host);
    const pathname = slugPart(url.pathname).slice(0, 80);
    return pathname ? `${host}-${pathname}` : host;
  } catch {
    return slugPart(value).slice(0, 100);
  }
};

const textBody = (text: string | undefined): BodyCapture => {
  if (!text) return null;
  return { encoding: "utf8", bytes: Buffer.byteLength(text), text };
};

const responseBody = (body: string, base64Encoded: boolean): BodyCapture => {
  if (!body) return null;
  if (!base64Encoded) return textBody(body);
  return { encoding: "base64", bytes: Buffer.from(body, "base64").length, text: body };
};

const requestFile = (runDir: string, id: string, method: string, url: string) => {
  return path.join(runDir, `${safeIso()}--${id}--${slugPart(method)}--${slugUrl(url)}.json`);
};

const writeRecord = async (record: RequestRecord) => {
  await fs.writeFile(record.file, `${JSON.stringify(record, null, 2)}\n`);
};

const trackWrite = (state: NetworkState, promise: Promise<unknown>) => {
  const tracked = promise.catch((error) => console.error(error)).finally(() => state.pendingWrites.delete(tracked));
  state.pendingWrites.add(tracked);
};

const nextId = (state: NetworkState) => {
  state.sequence += 1;
  return String(state.sequence).padStart(4, "0");
};

const createNetworkState = (runDir: string): NetworkState => ({
  runDir,
  records: new Map(),
  pendingWrites: new Set(),
  sequence: 0,
});

const createRecord = (state: NetworkState, requestId: string, params: any) => {
  const id = nextId(state);
  const request = params.request;
  const record = {
    id,
    file: requestFile(state.runDir, id, request.method, request.url),
    startedAt: new Date().toISOString(),
    request: {
      method: request.method,
      url: request.url,
      resourceType: params.type ?? "unknown",
      headers: request.headers ?? {},
      body: textBody(request.postData),
    },
    response: null,
    failure: null,
  } satisfies RequestRecord;

  state.records.set(requestId, record);
  console.log(`AGENT_BROWSER_REQUEST_CAPTURE_FILE=${record.file}`);
  trackWrite(state, fs.appendFile(path.join(state.runDir, "files.txt"), `${record.file}\n`));
  trackWrite(state, writeRecord(record));
};

const updateRequestHeaders = (state: NetworkState, params: any) => {
  const record = state.records.get(params.requestId);
  if (!record) return;
  record.request.headers = params.headers ?? record.request.headers;
  trackWrite(state, writeRecord(record));
};

const updateResponse = (state: NetworkState, params: any) => {
  const record = state.records.get(params.requestId);
  if (!record) return;
  record.response = {
    receivedAt: new Date().toISOString(),
    status: params.response.status,
    statusText: params.response.statusText ?? "",
    headers: params.response.headers ?? {},
    body: null,
  };
  trackWrite(state, writeRecord(record));
};

const updateResponseHeaders = (state: NetworkState, params: any) => {
  const record = state.records.get(params.requestId);
  if (!record) return;
  record.response = record.response ?? {
    receivedAt: new Date().toISOString(),
    status: params.statusCode,
    statusText: "",
    headers: {},
    body: null,
  };
  record.response.headers = params.headers ?? record.response.headers;
  trackWrite(state, writeRecord(record));
};

const updateResponseBody = async (state: NetworkState, client: CdpClient, params: any) => {
  const record = state.records.get(params.requestId);
  if (!record?.response) return;

  try {
    const result = await client.send("Network.getResponseBody", { requestId: params.requestId });
    record.response.body = responseBody(result.body, Boolean(result.base64Encoded));
  } catch (error) {
    record.response.body = { error: error instanceof Error ? error.message : String(error) };
  }

  await writeRecord(record);
};

const updateFailure = (state: NetworkState, params: any) => {
  const record = state.records.get(params.requestId);
  if (!record) return;
  record.failure = { failedAt: new Date().toISOString(), error: params.errorText ?? params };
  trackWrite(state, writeRecord(record));
};

const openWebSocket = (url: string) => new Promise<WebSocket>((resolve, reject) => {
  const ws = new WebSocket(url);
  ws.addEventListener("open", () => resolve(ws));
  ws.addEventListener("error", reject);
});

const createCdpClient = async (url: string, state: NetworkState): Promise<CdpClient> => {
  const ws = await openWebSocket(url);
  const pending = new Map<number, { resolve: (value: any) => void; reject: (reason: unknown) => void }>();
  let id = 0;

  const client: CdpClient = {
    ws,
    send: (method, params = {}) => new Promise((resolve, reject) => {
      id += 1;
      pending.set(id, { resolve, reject });
      ws.send(JSON.stringify({ id, method, params }));
    }),
  };

  ws.addEventListener("message", (event) => {
    const message = JSON.parse(String(event.data));
    if (message.id) {
      const request = pending.get(message.id);
      pending.delete(message.id);
      message.error ? request?.reject(message.error) : request?.resolve(message.result);
      return;
    }

    handleCdpEvent(state, client, message.method, message.params);
  });

  return client;
};

const handleCdpEvent = (state: NetworkState, client: CdpClient, method: string, params: any) => {
  if (method === "Network.requestWillBeSent") createRecord(state, params.requestId, params);
  if (method === "Network.requestWillBeSentExtraInfo") updateRequestHeaders(state, params);
  if (method === "Network.responseReceived") updateResponse(state, params);
  if (method === "Network.responseReceivedExtraInfo") updateResponseHeaders(state, params);
  if (method === "Network.loadingFinished") trackWrite(state, updateResponseBody(state, client, params));
  if (method === "Network.loadingFailed") updateFailure(state, params);
};

const pageWebSocketUrls = async (cdpUrl: string) => {
  if (cdpUrl.includes("/devtools/page/")) return [cdpUrl];

  const listUrl = cdpUrl.replace(/^ws:/, "http:").replace(/^wss:/, "https:").replace(/\/devtools\/browser\/.+$/, "/json/list");
  const response = await fetch(listUrl);
  const targets = await response.json() as Array<{ type: string; webSocketDebuggerUrl?: string }>;
  return targets.filter((target) => target.type === "page" && target.webSocketDebuggerUrl).map((target) => target.webSocketDebuggerUrl as string);
};

const attachToPages = async (state: NetworkState, cdpUrl: string) => {
  const urls = await pageWebSocketUrls(cdpUrl);
  const clients = await Promise.all(urls.map((url) => createCdpClient(url, state)));
  await Promise.all(clients.map((client) => client.send("Network.enable")));
  return clients;
};

const waitForStop = () => new Promise<void>((resolve) => {
  process.once("SIGTERM", resolve);
  process.once("SIGINT", resolve);
});

const record = async (runDir: string | undefined, cdpUrl: string | undefined) => {
  if (!runDir) throw new Error("missing run dir");
  if (!cdpUrl) throw new Error("missing CDP URL");

  const state = createNetworkState(runDir);
  const clients = await attachToPages(state, cdpUrl);
  await fs.writeFile(path.join(runDir, "ready"), "1\n");

  await waitForStop();
  await Promise.allSettled([...state.pendingWrites]);
  clients.forEach((client) => client.ws.close());
};

const main = async () => {
  const [command, runDir, cdpUrl] = process.argv.slice(2);
  if (command !== "record") throw new Error("expected record command");
  await record(runDir, cdpUrl);
};

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
