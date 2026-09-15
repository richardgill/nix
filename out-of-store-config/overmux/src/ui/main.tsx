import { OvermuxHost } from "overmux/client";
import { createRoot } from "react-dom/client";

import definition from "./app";

const root = document.querySelector("#root");
if (!root) {
  throw new Error("Missing root element");
}

createRoot(root).render(<OvermuxHost definition={definition} />);
