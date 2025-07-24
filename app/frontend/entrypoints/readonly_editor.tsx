import React from "react";
import { createRoot, Root } from "react-dom/client";
import ReadOnlyTipTap from "./components/ReadOnlyTipTap";

type EditorData = {
  content: string;
};

const mountedRoots = new Map<Element, Root>();

export function mountReadOnlyEditor(element: HTMLElement | null): void {
  if (!element) return;

  const id = element.id; // e.g. "readonly-editor-42"
  const jsonEl = document.querySelector<HTMLElement>(
    `#${id.replace("editor", "editor-data")}`
  );
  if (!jsonEl) return;

  let content = "";
  try {
    const parsed = JSON.parse(jsonEl.textContent || "{}") as EditorData;
    content = parsed.content;
  } catch (e) {
    console.warn("Invalid JSON in editor-data element:", e);
    return;
  }

  const prevRoot = mountedRoots.get(element);
  if (prevRoot) {
    prevRoot.unmount();
    mountedRoots.delete(element);
  }

  const root = createRoot(element);
  root.render(<ReadOnlyTipTap content={content} />);
  mountedRoots.set(element, root);
}

// Turbo Drive / Turbo Native / Turbo Streams 対応
document.addEventListener("turbo:load", () => {
  document.querySelectorAll<HTMLElement>(".readonly-editor-root").forEach((el) => {
    mountReadOnlyEditor(el);
  });
});