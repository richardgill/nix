// @vitest-environment happy-dom
import { act, useState } from "react";
import { createRoot } from "react-dom/client";
import { afterEach, expect, test as testCases, vi } from "vitest";

import { commands } from "./commands";

type NativeWebViewProps = {
  passthroughBindings?: readonly unknown[];
  url: string;
};
type Deferred<T> = {
  promise: Promise<T>;
  reject: (cause: Error) => void;
  resolve: (value: T) => void;
};

const nativeWebView = vi.hoisted(() => ({
  props: undefined as NativeWebViewProps | undefined,
}));
vi.mock("overmux/client", async (importOriginal) => ({
  ...(await importOriginal<typeof import("overmux/client")>()),
  NativeWebView: (props: NativeWebViewProps) => {
    nativeWebView.props = props;
    return <div data-native-web-view />;
  },
  useCommands: () => [
    {
      bindings: [
        ["§", "D", "D"],
        ["F12", "D", "D"],
      ],
    },
  ],
}));

import {
  PullRequestDialog,
  usePullRequestDialog,
} from "./pull-request-dialog";

Object.assign(globalThis, { IS_REACT_ACT_ENVIRONMENT: true });

const deferred = <T,>(): Deferred<T> => {
  let reject: Deferred<T>["reject"];
  let resolve: Deferred<T>["resolve"];
  const promise = new Promise<T>((nextResolve, nextReject) => {
    resolve = nextResolve;
    reject = nextReject;
  });
  return { promise, reject: reject!, resolve: resolve! };
};

const Probe = ({
  findPullRequest,
  onCloseAutoFocus,
}: {
  findPullRequest: (cwd: string) => Promise<{ url: string }>;
  onCloseAutoFocus: () => void;
}) => {
  const dialog = usePullRequestDialog({ findPullRequest });
  const [cwd, setCwd] = useState("/repo/first");

  return (
    <>
      <button onClick={() => dialog.open({ cwd })}>Find pull request</button>
      <button onClick={() => setCwd("/repo/second")}>Select second pane</button>
      <button onClick={() => setCwd("/repo/error")}>Select error pane</button>
      <PullRequestDialog
        onCloseAutoFocus={onCloseAutoFocus}
        onOpenChange={dialog.close}
        target={dialog.target}
      />
    </>
  );
};

const click = async (label: string) => {
  await act(async () => {
    [...document.querySelectorAll<HTMLButtonElement>("button")]
      .find((button) => button.textContent === label)
      ?.click();
  });
};

const press = async (key: string) => {
  await act(async () => {
    document.querySelector("[role=dialog]")?.dispatchEvent(
      new KeyboardEvent("keydown", { bubbles: true, cancelable: true, key }),
    );
  });
};

const OpenPullRequestDialog = ({
  onCloseAutoFocus,
}: {
  onCloseAutoFocus: () => void;
}) => {
  const [open, setOpen] = useState(true);

  return (
    <PullRequestDialog
      onCloseAutoFocus={onCloseAutoFocus}
      onOpenChange={setOpen}
      target={
        open
          ? {
              cwd: "/repo",
              id: 1,
              status: "success",
              url: "https://github.com/acme/repo/pull/1",
            }
          : undefined
      }
    />
  );
};

let container: HTMLDivElement;
let root: ReturnType<typeof createRoot>;

afterEach(async () => {
  await act(async () => root.unmount());
  container.remove();
});

testCases("keeps the captured folder while loading and ignores late results", async () => {
  const first = deferred<{ url: string }>();
  const second = deferred<{ url: string }>();
  const failure = deferred<{ url: string }>();
  const findPullRequest = vi
    .fn<(cwd: string) => Promise<{ url: string }>>()
    .mockReturnValueOnce(first.promise)
    .mockReturnValueOnce(second.promise)
    .mockReturnValueOnce(failure.promise);
  const restoredFocus = vi.fn();
  container = document.createElement("div");
  document.body.append(container);
  root = createRoot(container);

  expect(commands.openPullRequest.defaultBindings).toEqual([
    ["§", "P", "R"],
    ["F12", "P", "R"],
  ]);

  await act(async () =>
    root.render(
      <Probe
        findPullRequest={findPullRequest}
        onCloseAutoFocus={restoredFocus}
      />,
    ),
  );
  await click("Find pull request");
  const dialog = document.querySelector("[role=dialog]");
  expect(dialog?.querySelector("header")).toBeNull();
  expect(dialog?.querySelector("button")).toBeNull();
  expect(dialog?.querySelector("h2.sr-only")?.textContent).toBe("Pull request");
  expect(dialog?.className).toContain("w-full!");
  expect(
    dialog?.classList.contains(
      "[@media(min-width:768px)_and_(pointer:fine)]:w-[calc(100%-2rem)]!",
    ),
  ).toBe(false);
  expect(document.querySelector("[role=status]")?.textContent).toContain(
    "/repo/first",
  );

  await press("Escape");
  await click("Select second pane");
  await click("Find pull request");
  expect(document.querySelector("[role=status]")?.textContent).toContain(
    "/repo/second",
  );

  await act(async () => first.resolve({ url: "https://github.com/acme/first/pull/1" }));
  expect(document.querySelector("[role=status]")?.textContent).toContain(
    "/repo/second",
  );

  await act(async () => second.resolve({ url: "https://github.com/acme/second/pull/2" }));
  expect(nativeWebView.props?.url).toBe(
    "https://github.com/acme/second/pull/2/files",
  );
  const webView = document.querySelector("[data-native-web-view]");
  expect(webView).not.toBeNull();
  expect(webView?.parentElement?.classList.contains("p-[2px]")).toBe(true);
  expect(nativeWebView.props?.passthroughBindings).toEqual(
    expect.arrayContaining([
      "Escape",
      "Q",
      ["§", "D", "D"],
      ["F12", "D", "D"],
    ]),
  );

  await press("q");
  expect(document.querySelector("[data-native-web-view]")).toBeNull();
  expect(restoredFocus).toHaveBeenCalled();

  await click("Select error pane");
  await click("Find pull request");
  await act(async () =>
    failure.reject(new Error("No pull request was found for the current branch.")),
  );
  expect(document.querySelector("[role=alert]")?.textContent).toContain(
    "No pull request was found for the current branch.",
  );
});

testCases.each(["Escape", "q"])(
  "%s closes the headerless dialog and unmounts the native view",
  async (key) => {
    const restoredFocus = vi.fn();
    container = document.createElement("div");
    document.body.append(container);
    root = createRoot(container);

    await act(async () =>
      root.render(
        <OpenPullRequestDialog onCloseAutoFocus={restoredFocus} />,
      ),
    );
    expect(document.querySelector("[data-native-web-view]")).not.toBeNull();
    expect(nativeWebView.props?.url).toBe(
      "https://github.com/acme/repo/pull/1/files",
    );

    await press(key);

    expect(document.querySelector("[data-native-web-view]")).toBeNull();
    await vi.waitFor(() => expect(restoredFocus).toHaveBeenCalled());
  },
);
