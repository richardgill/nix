import tailwindcss from "@tailwindcss/vite";
import viteReact from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  root: "src/ui",
  build: { emptyOutDir: true, outDir: "../../dist" },
  plugins: [tailwindcss(), viteReact()],
  resolve: { dedupe: ["react", "react-dom"] },
  server: {
    // Do not cache an empty transform while an editor or formatter rewrites a file.
    watch: { awaitWriteFinish: { stabilityThreshold: 100, pollInterval: 10 } },
  },
});
