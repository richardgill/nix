export const cn = (...values: Array<string | false | null | undefined>) =>
  values.filter(Boolean).join(" ");
