import React from "react"
import { createRoot, Root } from "react-dom/client"
import RichEditor from "./components/RichEditor"

const mountedRoots = new Map<Element, Root>()

export function mountRichEditor(selectorOrElement: string | Element): void {
  const element =
    typeof selectorOrElement === "string"
      ? document.querySelector<HTMLElement>(selectorOrElement)
      : selectorOrElement

  if (!element) return

  const prevRoot = mountedRoots.get(element)
  if (prevRoot) {
    prevRoot.unmount()
    mountedRoots.delete(element)
  }

  const root = createRoot(element)
  root.render(<RichEditor element={element as HTMLElement} />)
  mountedRoots.set(element, root)
}

// Turbo対応：全体エディタ用
document.addEventListener("turbo:load", () => {
  document.querySelectorAll<HTMLElement>(".rich-editor-root").forEach((el) => {
    mountRichEditor(el)
  })
})