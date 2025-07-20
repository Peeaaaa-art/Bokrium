import React from "react";
import { createRoot } from "react-dom/client";
import ReadOnlyTipTap from "./components/ReadOnlyTipTap.jsx";

const mountedRoots = new Map();

export function mountReadOnlyEditor(element) {
  if (!element) return;

  const id = element.id; // e.g. "readonly-editor-42"
  const jsonEl = document.querySelector(`#${id.replace("editor", "editor-data")}`);
  if (!jsonEl) return;

  const { content } = JSON.parse(jsonEl.textContent || "{}");

  const prevRoot = mountedRoots.get(element);
  if (prevRoot) {
    prevRoot.unmount();
    mountedRoots.delete(element);
  }

  const root = createRoot(element);
  root.render(<ReadOnlyTipTap content={content} />);
  mountedRoots.set(element, root);
}

document.addEventListener("turbo:load", () => {
  document.querySelectorAll(".readonly-editor-root").forEach((el) => {
    mountReadOnlyEditor(el);
  });
});