import React from "react"
import { createRoot, Root } from "react-dom/client"
import HandwrittenNoteEditor from "./components/HandwrittenNoteEditor"
import "../styles/handwritten_note.css"

let mountedRoot: Root | null = null
let mountedElement: HTMLElement | null = null

function mountHandwrittenNote(): void {
  const element = document.querySelector<HTMLElement>("#handwritten-note-root")

  // 即時マウント直後のturbo:loadなど、同じ要素への二重マウントを防ぐ
  if (element && element === mountedElement && mountedRoot) return

  if (mountedRoot) {
    mountedRoot.unmount()
    mountedRoot = null
    mountedElement = null
  }
  if (!element) return

  const updateUrl = element.dataset.updateUrl
  const thumbnailUrl = element.dataset.thumbnailUrl
  if (!updateUrl || !thumbnailUrl) return
  const viewMode = element.dataset.viewMode === "true"
  const thumbnailMissing = element.dataset.thumbnailMissing === "true"

  let initialSceneData = {}
  const dataScript = document.querySelector("#handwritten-note-data")
  if (dataScript?.textContent) {
    try {
      initialSceneData = JSON.parse(dataScript.textContent).data ?? {}
    } catch {
      initialSceneData = {}
    }
  }

  mountedRoot = createRoot(element)
  mountedElement = element
  mountedRoot.render(
    <HandwrittenNoteEditor
      updateUrl={updateUrl}
      thumbnailUrl={thumbnailUrl}
      viewMode={viewMode}
      thumbnailMissing={thumbnailMissing}
      initialSceneData={initialSceneData}
    />
  )
}

document.addEventListener("turbo:load", mountHandwrittenNote)

// Turbo遷移でこのentrypointが初めて読み込まれた場合、
// モジュール評価時点でturbo:loadは発火済みなので、即時マウントも試みる
mountHandwrittenNote()
