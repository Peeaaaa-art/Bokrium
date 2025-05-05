import React, { useEffect, useRef } from "react"
import { useEditor, EditorContent, BubbleMenu } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"
import BubbleMenuExtension from "@tiptap/extension-bubble-menu"

const RichEditor = ({ element }) => {
  const initialContent = element?.dataset?.initialContent || ""

  const decodeHTML = (html) => {
    const textarea = document.createElement("textarea")
    textarea.innerHTML = html
    return textarea.value
  }

  const cleanHTML = (html) => {
    return html
      .replace(/<p><br(?: class="ProseMirror-trailingBreak")?><\/p>\s*$/g, "")
      .replace(/(<p><br><\/p>\s*)+$/g, "")
      .replace(/(<p>(<br\s*\/?>)*<\/p>\s*)+$/g, "")
  }

  const editor = useEditor({
    extensions: [
      StarterKit,
      BubbleMenuExtension,
    ],
    content: decodeHTML(initialContent),
    autofocus: true,
    editable: true,
    onUpdate: ({ editor }) => {
      const html = cleanHTML(editor.getHTML())
      const hiddenField = document.getElementById("memo_content_input")
      if (hiddenField) hiddenField.value = html
      window.hasUnsavedChanges = true
      console.log("📝 onUpdate: hasUnsavedChanges = true")
    }
  })

  useEffect(() => {
    if (!editor) return

    const hiddenField = document.getElementById("memo_content_input")
    if (hiddenField) hiddenField.value = cleanHTML(editor.getHTML())

    const updateHandler = () => {
      const html = cleanHTML(editor.getHTML())
      if (hiddenField) hiddenField.value = html
      window.hasUnsavedChanges = true
      console.log("✏️ [event] editor updated → hasUnsavedChanges = true")
    }

    editor.on("update", updateHandler)
    return () => editor.off("update", updateHandler)
  }, [editor])

  if (!editor) return null

  return (
    <div className="form-control rhodia-grid-bg" style={{ overflowY: "auto", position: "relative" }}>
      <BubbleMenu editor={editor} tippyOptions={{ duration: 150 }}>
        <div className="bubble-menu bg-white border rounded shadow-sm p-2 d-flex flex-wrap gap-2">
          <button
            type="button"
            onClick={() => editor.chain().focus().undo().run()}
            className="btn btn-sm btn-outline-secondary"
            title="元に戻す"
          >
            <i class="bi bi-arrow-left"></i>
          </button>

          <button
            type="button"
            onClick={() => editor.chain().focus().redo().run()}
            className="btn btn-sm btn-outline-secondary"
            title="やり直す"
          >
            <i class="bi bi-arrow-right"></i>
          </button>
          <button
            type="button"
            onClick={() => editor.chain().focus().toggleBold().run()}
            className={`btn btn-sm btn-outline-secondary ${editor.isActive("bold") ? "active" : ""}`}
          >
            <b>B</b>
          </button>

          <button
            type="button"
            onClick={() => editor.chain().focus().toggleItalic().run()}
            className={`btn btn-sm btn-outline-secondary ${editor.isActive("italic") ? "active" : ""}`}
          >
            <i>I</i>
          </button>

          <button
            type="button"
            onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()}
            className={`btn btn-sm btn-outline-secondary ${editor.isActive("heading", { level: 1 }) ? "active" : ""}`}
          >
            H1
          </button>

          <button
            type="button"
            onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()}
            className={`btn btn-sm btn-outline-secondary ${editor.isActive("heading", { level: 2 }) ? "active" : ""}`}
          >
            H2
          </button>

          <button
            type="button"
            onClick={() => editor.chain().focus().toggleBulletList().run()}
            className={`btn btn-sm btn-outline-secondary ${editor.isActive("bulletList") ? "active" : ""}`}
          >
            • List
          </button>

          <button
            type="button"
            onClick={() => editor.chain().focus().toggleOrderedList().run()}
            className={`btn btn-sm btn-outline-secondary ${editor.isActive("orderedList") ? "active" : ""}`}
          >
            1. List
          </button>

          <button
            type="button"
            onClick={() => editor.chain().focus().toggleBlockquote().run()}
            className={`btn btn-sm btn-outline-secondary ${editor.isActive("blockquote") ? "active" : ""}`}
          >
            &gt; 引用
          </button>

          <button
            type="button"
            onClick={() => editor.chain().focus().toggleCodeBlock().run()}
            className={`btn btn-sm btn-outline-secondary ${editor.isActive("codeBlock") ? "active" : ""}`}
          >
            {"</>"}
          </button>
        </div>
      </BubbleMenu>
      <EditorContent editor={editor} className="w-100 ProseMirror" />
    </div>
  )
}

export default RichEditor