// =========================
// ReadOnlyTipTap（表示専用）
// =========================
import React from "react"
import { useEditor, EditorContent } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"

// 表示用でも classなし <br> を除去（防止）
const removeUnwantedBRs = (html) => {
  const div = document.createElement("div")
  div.innerHTML = html
  div.querySelectorAll("p").forEach((p) => {
    const brs = p.querySelectorAll("br")
    brs.forEach((br) => {
      if (!br.classList.contains("ProseMirror-trailingBreak")) {
        if (p.textContent.trim() === "" && p.querySelector(".ProseMirror-trailingBreak")) {
          br.remove()
        }
      }
    })
  })
  return div.innerHTML
}

const ReadOnlyTipTap = ({ content }) => {
  const cleaned = removeUnwantedBRs(content)

  const editor = useEditor({
    extensions: [StarterKit],
    content: cleaned,
    editable: false,
  })

  if (!editor) return null

  return <EditorContent editor={editor} />
}

export default ReadOnlyTipTap
