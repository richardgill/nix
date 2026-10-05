// Encodes accessory keys and single-character phone commits with one-shot Ctrl and Alt.
// Native modified keys and paste bypass this encoding at their origin-aware caller.

export type TerminalModifiers = { alt: boolean; ctrl: boolean };

const controlCharacter = (input: string) => {
  const character = input[0];
  if (!character) return input;
  const code = character.charCodeAt(0);
  if ((code >= 64 && code <= 95) || (code >= 97 && code <= 122)) {
    return String.fromCharCode(code & 31);
  }
  if (character === "/") return "\u001f";
  if (character === "?") return "\u007f";
  return character === " " ? "\0" : input;
};

export const applyTerminalModifiers = (
  input: string,
  modifiers: TerminalModifiers,
) => {
  const arrow = input.match(/^\u001b(?:\[|O)([ABCD])$/)?.[1];
  if (!arrow && input.length !== 1) return input;
  if (arrow && (modifiers.alt || modifiers.ctrl)) {
    const parameter =
      1 + Number(modifiers.alt) * 2 + Number(modifiers.ctrl) * 4;
    return `\u001b[1;${parameter}${arrow}`;
  }
  const modified = modifiers.ctrl ? controlCharacter(input) : input;
  return modifiers.alt ? `\u001b${modified}` : modified;
};
