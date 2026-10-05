import {
  NativeWebView,
  type NativeWebViewLoadError,
  type ShortcutBinding,
  useCommands,
} from "overmux/client";
import { useEffect, useRef, useState } from "react";

import { FullscreenDialog } from "./components/fullscreen-dialog";
import { DialogTitle } from "./shadcn/dialog";

export type PullRequestTarget =
  | { cwd: string; id: number; status: "loading" }
  | { cwd: string; id: number; status: "error"; message: string }
  | { cwd: string; id: number; status: "success"; url: string };

type PullRequestLookup = (cwd: string) => Promise<{ url: string }>;

const isPrefixBinding = (
  binding: ShortcutBinding,
): binding is Exclude<ShortcutBinding, string> =>
  Array.isArray(binding) && (binding[0] === "§" || binding[0] === "F12");

export const usePullRequestDialog = ({
  findPullRequest,
}: {
  findPullRequest: PullRequestLookup;
}) => {
  const [target, setTarget] = useState<PullRequestTarget>();
  const request = useRef(0);

  const open = ({ cwd }: { cwd?: string }) => {
    const id = request.current + 1;
    request.current = id;
    if (!cwd) {
      setTarget({
        cwd: "this terminal",
        id,
        message: "No active terminal folder is available.",
        status: "error",
      });
      return;
    }
    setTarget({ cwd, id, status: "loading" });
    void findPullRequest(cwd)
      .then(({ url }) => {
        if (request.current === id) {
          setTarget({ cwd, id, status: "success", url });
        }
      })
      .catch((cause: unknown) => {
        if (request.current === id) {
          setTarget({
            cwd,
            id,
            message:
              cause instanceof Error
                ? cause.message
                : "Could not find a pull request for this folder.",
            status: "error",
          });
        }
      });
  };

  const close = (open: boolean) => {
    if (open) return;
    request.current += 1;
    setTarget(undefined);
  };

  return { close, open, target };
};

export const PullRequestDialog = ({
  onCloseAutoFocus,
  onOpenChange,
  target,
}: {
  onCloseAutoFocus?: () => void;
  onOpenChange: (open: boolean) => void;
  target: PullRequestTarget | undefined;
}) => {
  const [loadError, setLoadError] = useState<NativeWebViewLoadError>();
  const prefixBindings = useCommands()
    .flatMap((command) => command.bindings)
    .filter(isPrefixBinding);
  const passthroughBindings = ["Escape", "Q", ...prefixBindings];

  useEffect(() => {
    setLoadError(undefined);
  }, [target?.id]);

  return (
    <FullscreenDialog
      edgeToEdge
      hideCloseButton
      onClose={() => onOpenChange(false)}
      onCloseAutoFocus={onCloseAutoFocus}
      open={Boolean(target)}
    >
      <DialogTitle className="sr-only">Pull request</DialogTitle>
      {target?.status === "loading" ? (
        <p className="p-4 text-sm text-muted-foreground" role="status">
          Finding a pull request for {target.cwd}…
        </p>
      ) : null}
      {target?.status === "error" ? (
        <p className="p-4 text-sm text-[var(--om-color-danger)]" role="alert">
          {target.message}
        </p>
      ) : null}
      {target?.status === "success" && loadError ? (
        <p
          className="shrink-0 border-b border-border px-4 py-2 text-sm text-[var(--om-color-danger)]"
          role="alert"
        >
          Could not load this pull request ({loadError.code}):{" "}
          {loadError.message}
        </p>
      ) : null}
      {target?.status === "success" ? (
        <div className="min-h-0 flex-1 p-[2px]">
          <NativeWebView
            className="h-full w-full"
            onLoadError={setLoadError}
            passthroughBindings={passthroughBindings}
            style={{ height: "100%", width: "100%" }}
            url={`${target.url}/files`}
          />
        </div>
      ) : null}
    </FullscreenDialog>
  );
};
