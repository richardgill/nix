import { defineOvermuxConfig } from "overmux";

import server from "./src/server";

export default defineOvermuxConfig({
  auth: {
    mode: "cli-login",
    sessionLifetime: "forever",
    origins: [
      "http://localhost:4242",
      "https://um790.tail98765.ts.net",
    ],
    trustedProxyPeer: "127.0.0.1",
  },
  debug: true,
  host: "127.0.0.1",
  port: 4242,
  productionWebAssetsDir: "./dist",
  server,
  vite: "./vite.config.ts",
});
