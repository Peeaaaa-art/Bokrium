// =========================
// RichEditor (編集用)
// =========================
import React, { useEffect } from "react"
import { useEditor, EditorContent, BubbleMenu } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"
import BubbleMenuExtension from "@tiptap/extension-bubble-menu"
import CharacterCount from "@tiptap/extension-character-count"

// HTMLデコード
const decodeHTML = (html) => {
  const textarea = document.createElement("textarea")
  textarea.innerHTML = html
  return textarea.value
}

// 不要な<br>削除（classなし & trailingBreakと重複する場合）
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

const RichEditor = ({ element }) => {
  const initialRaw = element?.dataset?.initialContent || ""
  const inputId = element?.dataset?.inputId || "memo_content_input"
  const initialContent = decodeHTML(initialRaw)

  const editor = useEditor({
    extensions: [
      StarterKit,
      BubbleMenuExtension,
      CharacterCount.configure({ limit: 10000 }),
    ],
    content: initialContent,
    autofocus: true,
    editable: true,
  })

  useEffect(() => {
    if (!editor) return

    const hiddenField = document.getElementById(inputId)
    const saveButton = document.querySelector("[data-action='click->memo-modal#forceSubmit']")

    let previousHTML = removeUnwantedBRs(editor.getHTML())
    if (hiddenField) hiddenField.value = previousHTML

    // 初期状態で保存ボタンを無効化
    if (saveButton) {
      saveButton.disabled = true
      saveButton.classList.add("disabled")
    }

    const updateHandler = () => {
      const currentHTML = removeUnwantedBRs(editor.getHTML())

      // 内容が変わった → 保存ボタン有効化
      if (currentHTML !== previousHTML) {
        if (hiddenField) hiddenField.value = currentHTML
        if (saveButton) {
          saveButton.disabled = false
          saveButton.classList.remove("disabled")
        }
        window.hasUnsavedChanges = true
      } else {
        // 内容が戻った → 保存ボタン無効化
        if (saveButton) {
          saveButton.disabled = true
          saveButton.classList.add("disabled")
        }
        window.hasUnsavedChanges = false
      }

      const charCountEl = document.getElementById("char-count")
      if (charCountEl) {
        const count = editor?.storage?.characterCount?.characters?.() || 0
        charCountEl.textContent = `${count} 文字`
      }
    }

    // 初期化時にも一度チェック
    updateHandler()

    editor.on("update", updateHandler)
    return () => editor.off("update", updateHandler)
  }, [editor])

  if (!editor) return null

  return (
    <div className="rhodia-grid-bg" style={{ overflowY: "auto", position: "relative" }}>
      <BubbleMenu editor={editor} tippyOptions={{ duration: 150 }}>
        <div className="bubble-menu bg-white border rounded shadow-sm p-2 d-flex flex-wrap gap-2">
          <button type="button" onClick={() => editor.chain().focus().undo().run()} className="btn btn-sm btn-outline-secondary" title="元に戻す">
            ←
          </button>
          <button type="button" onClick={() => editor.chain().focus().redo().run()} className="btn btn-sm btn-outline-secondary" title="やり直す">
            →
          </button>
          <button type="button" onClick={() => editor.chain().focus().toggleBold().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("bold") ? "active" : ""}`}>
            <b>B</b>
          </button>
          <button type="button" onClick={() => editor.chain().focus().toggleItalic().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("italic") ? "active" : ""}`}>
            <i>I</i>
          </button>
          <button type="button" onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("heading", { level: 1 }) ? "active" : ""}`}>
            H1
          </button>
          <button type="button" onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("heading", { level: 2 }) ? "active" : ""}`}>
            H2
          </button>
          <button type="button" onClick={() => editor.chain().focus().toggleBulletList().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("bulletList") ? "active" : ""}`}>
            • List
          </button>
          <button type="button" onClick={() => editor.chain().focus().toggleOrderedList().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("orderedList") ? "active" : ""}`}>
            1. List
          </button>
          <button type="button" onClick={() => editor.chain().focus().toggleBlockquote().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("blockquote") ? "active" : ""}`}>
            &gt; 引用
          </button>
          <button type="button" onClick={() => editor.chain().focus().toggleCodeBlock().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("codeBlock") ? "active" : ""}`}>
            {"</>"}
          </button>
        </div>
      </BubbleMenu>
      <EditorContent editor={editor} className="w-100 ProseMirror" />
    </div>
  )
}

export default RichEditor