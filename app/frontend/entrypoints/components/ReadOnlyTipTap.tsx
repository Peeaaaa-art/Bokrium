// =========================
// ReadOnlyTipTap（表示専用）
// =========================
import React from "react";
import { useEditor, EditorContent } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"
import type { ReactElement } from "react"
import { createMemoLinkExtension, prepareMemoHtmlForDisplay } from "../utils/memo_links"
import { normalizeProseMirrorHtmlForSave } from "../utils/prosemirror_html"

interface ReadOnlyTipTapProps {
  content: string
}

function ReadOnlyTipTap({ content }: ReadOnlyTipTapProps): ReactElement | null {
  const sanitized = prepareMemoHtmlForDisplay(content)
  const cleaned = normalizeProseMirrorHtmlForSave(sanitized)

  const editor = useEditor({
    extensions: [StarterKit, createMemoLinkExtension(true)],
    content: cleaned,
    editable: false,
  })

  if (!editor) return null

  const stopLinkClickPropagation = (event: React.MouseEvent<HTMLDivElement>) => {
    if ((event.target as HTMLElement).closest("a")) {
      event.stopPropagation()
    }
  }

  return (
    <div onClickCapture={stopLinkClickPropagation}>
      <EditorContent editor={editor} />
    </div>
  )
}

export default ReadOnlyTipTap
