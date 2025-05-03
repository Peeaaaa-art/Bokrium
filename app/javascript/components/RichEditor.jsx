import React, { useEffect } from "react"
import { createRoot } from "react-dom/client"
import { useEditor, EditorContent } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"

const mountedRoots = new Map()

const decodeHTML = (html) => {
  const textarea = document.createElement("textarea")
  textarea.innerHTML = html
  return textarea.value
}

const RichEditor = ({ element }) => {
  const memoId = element.dataset.memoId || "new"
  const initialContent = decodeHTML(element.dataset.initialContent || "")
  const hiddenFieldId = `memo_content_input_${memoId}`
  const hiddenField = document.getElementById(hiddenFieldId)

  const editor = useEditor({
    extensions: [StarterKit],
    content: initialContent,
    autofocus: false,
    editable: true,
    onUpdate: ({ editor }) => {
      if (hiddenField) hiddenField.value = editor.getHTML()
    },
  })

  useEffect(() => {
    if (editor && hiddenField) {
      hiddenField.value = editor.getHTML()
    }
  }, [editor])

  if (!editor) return null

  return (
    <div className="form-control rhodia-grid-bg" style={{ overflowY: "auto" }}>
      <EditorContent editor={editor} className="w-100 ProseMirror" />
    </div>
  )
}

export function mountEditors() {
  document.querySelectorAll(".rich-editor-root").forEach((element) => {
    mountRichEditor(element)
  })
}

export function mountRichEditor(selectorOrElement) {
  const element =
    typeof selectorOrElement === "string"
      ? document.querySelector(selectorOrElement)
      : selectorOrElement

  if (!element) return

  const prevRoot = mountedRoots.get(element)
  if (prevRoot) {
    prevRoot.unmount()
    mountedRoots.delete(element)
  }

  const root = createRoot(element)
  root.render(<RichEditor element={element} />)
  mountedRoots.set(element, root)
}

// Turboと連携
document.addEventListener("turbo:load", mountEditors)
document.addEventListener("turbo:frame-load", mountEditors)