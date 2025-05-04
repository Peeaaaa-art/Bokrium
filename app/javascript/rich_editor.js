// app/javascript/rich_editors.js
import React from "react";
import { createRoot } from "react-dom/client";
import RichEditor from "./components/RichEditor.jsx"; // ✅ 正しいやつを使う

const mountedRoots = new Map();

export function mountRichEditor(selectorOrElement) {
  const element =
    typeof selectorOrElement === "string"
      ? document.querySelector(selectorOrElement)
      : selectorOrElement;

  if (!element) return;

  const prevRoot = mountedRoots.get(element);
  if (prevRoot) {
    prevRoot.unmount();
    mountedRoots.delete(element);
  }

  const root = createRoot(element);
  root.render(<RichEditor element={element} />);
  mountedRoots.set(element, root);
}

// Turbo対応：全体エディタ用
document.addEventListener("turbo:load", () => {
  document.querySelectorAll(".rich-editor-root").forEach((el) => {
    mountRichEditor(el);
  });
});