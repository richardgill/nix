import { createOvermuxHooks } from "overmux/client";

export type ServerConfig = typeof import("../../server").default;

export const { useOperation, useResource, useStream } =
  createOvermuxHooks<ServerConfig>();
