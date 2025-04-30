import React from "react";
import { createRoot } from "react-dom/client";
import RichEditor from "../components/RichEditor";

document.addEventListener("turbo:load", () => {
  const editorRoot = document.getElementById("rich-editor-root");
  if (editorRoot && !editorRoot.dataset.mounted) {
    editorRoot.dataset.mounted = "true"; // 二重マウント防止
    const root = createRoot(editorRoot);
    root.render(<RichEditor />);
  }
});