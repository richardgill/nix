// Shares one-shot modifiers between accessory keys and xterm's origin-aware phone/key input.
// Ref-backed state consumes synchronously, even when several inputs precede React's next render.

import type {
  XtermInputEvent,
  XtermTerminalHandle,
} from "@overmux/xterm/react";
import { useRef, useState, type PointerEvent, type RefObject } from "react";

import {
  applyTerminalModifiers,
  type TerminalModifiers,
} from "../utils/apply-terminal-modifiers";

const noModifiers: TerminalModifiers = { alt: false, ctrl: false };

const keys = [
  { input: "\u001b", label: "Esc", name: "Escape" },
  { input: "\t", label: "Tab", name: "Tab" },
  { input: "/", label: "/", name: "Slash" },
  { input: "\\", label: "\\", name: "Backslash" },
  { input: "\u001b[D", label: "←", name: "Left arrow" },
  { input: "\u001b[B", label: "↓", name: "Down arrow" },
  { input: "\u001b[A", label: "↑", name: "Up arrow" },
  { input: "\u001b[C", label: "→", name: "Right arrow" },
];

export const useMobileTerminalKeys = (
  terminalRef: RefObject<XtermTerminalHandle | null>,
) => {
  const [modifiers, setModifiers] = useState(noModifiers);
  const pending = useRef(noModifiers);
  const clear = () => {
    pending.current = noModifiers;
    setModifiers(noModifiers);
  };
  const consume = (input: string, apply = true) => {
    const current = pending.current;
    clear();
    return apply ? applyTerminalModifiers(input, current) : input;
  };
  const transformInput = (event: XtermInputEvent) =>
    consume(
      event.data,
      event.kind === "text"
        ? event.data.length === 1
        : event.kind === "key" &&
            !(
              event.domEvent.ctrlKey ||
              event.domEvent.altKey ||
              event.domEvent.metaKey
            ),
    );
  const send = (input: string) => {
    const terminal = terminalRef.current;
    if (!terminal) return;
    terminal.input(consume(input));
    terminal.focus();
  };
  const toggleModifier = (modifier: keyof TerminalModifiers) => {
    pending.current = {
      ...pending.current,
      [modifier]: !pending.current[modifier],
    };
    setModifiers(pending.current);
    terminalRef.current?.focus();
  };
  return { clear, modifiers, send, toggleModifier, transformInput };
};

const preserveTerminalFocus = (event: PointerEvent<HTMLButtonElement>) =>
  event.preventDefault();

export const MobileTerminalKeys = ({
  modifiers,
  send,
  toggleModifier,
}: ReturnType<typeof useMobileTerminalKeys>) => {
  return (
    <div
      aria-label="Terminal keys"
      className="grid shrink-0 grid-cols-10 gap-px border-t border-border bg-panel-muted p-1 md:hidden"
      role="toolbar"
    >
      {keys.slice(0, 1).map((key) => (
        <button
          aria-label={key.name}
          className="min-w-0 rounded border border-border px-1 py-2 text-xs"
          key={key.name}
          onClick={() => send(key.input)}
          onPointerDown={preserveTerminalFocus}
          type="button"
        >
          {key.label}
        </button>
      ))}
      {(["alt", "ctrl"] as const).map((modifier) => (
        <button
          aria-label={modifier === "alt" ? "Alt" : "Ctrl"}
          aria-pressed={modifiers[modifier]}
          className="min-w-0 rounded border border-border px-1 py-2 text-xs data-[active=true]:bg-accent data-[active=true]:text-background"
          data-active={modifiers[modifier]}
          key={modifier}
          onClick={() => toggleModifier(modifier)}
          onPointerDown={preserveTerminalFocus}
          type="button"
        >
          {modifier === "alt" ? "Alt" : "Ctrl"}
        </button>
      ))}
      {keys.slice(1).map((key) => (
        <button
          aria-label={key.name}
          className="min-w-0 rounded border border-border px-1 py-2 text-xs"
          key={key.name}
          onClick={() => send(key.input)}
          onPointerDown={preserveTerminalFocus}
          type="button"
        >
          {key.label}
        </button>
      ))}
    </div>
  );
};
