// =========================
// ReadOnlyTipTap（表示専用）
// =========================
import React from "react";
import { useEditor, EditorContent } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"
import type { ReactElement } from "react"
import DOMPurify from "dompurify"

interface ReadOnlyTipTapProps {
  content: string
}

// 表示用でも classなし <br> を除去（防止）
const removeUnwantedBRs = (html: string): string => {
  // Use DOMParser for safer HTML parsing
  const parser = new DOMParser()
  const doc = parser.parseFromString(html, "text/html")
  const div = doc.body

  div.querySelectorAll("p").forEach((p) => {
    const hasOnlyBRs = Array.from(p.childNodes).every((node) => {
      return (
        node.nodeName === "BR" ||
        (node.nodeType === Node.ELEMENT_NODE &&
          (node as Element).classList.contains("ProseMirror-trailingBreak"))
      )
    })

    const isActuallyEmpty = (p.textContent?.trim() ?? "") === ""

    if (hasOnlyBRs || isActuallyEmpty) {
      // 空の段落は trailingBreak だけを残す
      // Clear all child nodes safely
      while (p.firstChild) {
        p.removeChild(p.firstChild)
      }
      const br = document.createElement("br")
      br.classList.add("ProseMirror-trailingBreak")
      p.appendChild(br)
    }
  })

  return div.innerHTML
}

function ReadOnlyTipTap({ content }: ReadOnlyTipTapProps): ReactElement | null {
  const sanitized = DOMPurify.sanitize(content)
  const cleaned = removeUnwantedBRs(sanitized)

  const editor = useEditor({
    extensions: [StarterKit],
    content: cleaned,
    editable: false,
  })

  if (!editor) return null

  return <EditorContent editor={editor} />
}

export default ReadOnlyTipTap