// app/javascript/components/RichEditor.jsx
import React, { useEffect } from "react"
import { useEditor, EditorContent } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"

const RichEditor = ({ element }) => {
  const initialContent = element?.dataset?.initialContent || ""

  const decodeHTML = (html) => {
    const textarea = document.createElement("textarea")
    textarea.innerHTML = html
    return textarea.value
  }

  const editor = useEditor({
    extensions: [StarterKit],
    content: decodeHTML(initialContent),
    autofocus: true,
    editable: true,
    onUpdate: ({ editor }) => {
      const html = editor.getHTML()
      const hiddenField = document.getElementById("memo_content_input")
      if (hiddenField) hiddenField.value = html
      window.hasUnsavedChanges = true // ✅ ←これが必須！
      console.log("📝 onUpdate: hasUnsavedChanges = true") // デバッグ用
    }
  })

  useEffect(() => {
    if (!editor) return
  
    const hiddenField = document.getElementById("memo_content_input")
    if (hiddenField) hiddenField.value = editor.getHTML()
  
    const updateHandler = () => {
      const html = editor.getHTML()
      if (hiddenField) hiddenField.value = html
      window.hasUnsavedChanges = true
      console.log("✏️ [event] editor updated → hasUnsavedChanges = true")
    }
  
    editor.on("update", updateHandler)
    return () => editor.off("update", updateHandler)
  }, [editor])
  

  if (!editor) return null

  return (
    <div className="form-control rhodia-grid-bg" style={{ overflowY: "auto" }}>
      <EditorContent editor={editor} className="w-100 ProseMirror" />
    </div>
  )
}

export default RichEditor