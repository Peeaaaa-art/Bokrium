// =========================
// RichEditor (編集用)
// =========================
import { useEffect } from "react"
import type { ReactElement } from "react"
import { useEditor, EditorContent, BubbleMenu } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"
import BubbleMenuExtension from "@tiptap/extension-bubble-menu"
import CharacterCount from "@tiptap/extension-character-count"

interface RichEditorProps {
  element: HTMLElement
}

const decodeHTML = (html: string): string => {
  const textarea = document.createElement("textarea")
  textarea.innerHTML = html
  return textarea.value
}

// 不要な<br>を削除（classなし & trailingBreakと重複する場合）
const removeUnwantedBRs = (html: string): string => {
  const div = document.createElement("div")
  div.innerHTML = html

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
      p.innerHTML = ""
      const br = document.createElement("br")
      br.classList.add("ProseMirror-trailingBreak")
      p.appendChild(br)
    }
  })

  return div.innerHTML
}

function RichEditor({ element }: RichEditorProps): ReactElement | null {
  const initialRaw = element.dataset.initialContent ?? ""
  const inputId = element.dataset.inputId ?? "memo_content_input"
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

    const hiddenField = document.getElementById(inputId) as HTMLInputElement | null
    const saveButton = document.querySelector(
      "[data-action='click->memo-modal#forceSubmit']"
    ) as HTMLButtonElement | null

    let previousHTML = removeUnwantedBRs(editor.getHTML())
    if (hiddenField) hiddenField.value = previousHTML

    if (saveButton) {
      saveButton.disabled = true
      saveButton.classList.add("disabled")
    }

    const updateHandler = () => {
      const currentHTML = removeUnwantedBRs(editor.getHTML())

      if (currentHTML !== previousHTML) {
        if (hiddenField) hiddenField.value = currentHTML
        if (saveButton) {
          saveButton.disabled = false
          saveButton.classList.remove("disabled")
        }
        window.hasUnsavedChanges = true
      } else {
        if (saveButton) {
          saveButton.disabled = true
          saveButton.classList.add("disabled")
        }
        window.hasUnsavedChanges = false
      }

      const charCountEl = document.getElementById("char-count")
      if (charCountEl) {
        const count = editor.storage.characterCount?.characters?.() || 0
        charCountEl.textContent = `${count} 文字`
      }
    }

    updateHandler()

    editor.on("update", updateHandler)
    return () => {
      editor.off("update", updateHandler)
    }
  }, [editor, inputId])

  if (!editor) return null

  return (
    <div className="rhodia-grid-bg" style={{ overflowY: "auto", position: "relative" }}>
      <BubbleMenu editor={editor} tippyOptions={{ duration: 150 }}>
        <div className="bubble-menu bg-white border rounded shadow-sm p-2 d-flex flex-wrap gap-2">
          <button type="button" onClick={() => editor.chain().focus().undo().run()} className="btn btn-sm btn-outline-secondary" title="元に戻す">←</button>
          <button type="button" onClick={() => editor.chain().focus().redo().run()} className="btn btn-sm btn-outline-secondary" title="やり直す">→</button>
          <button type="button" onClick={() => editor.chain().focus().toggleBold().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("bold") ? "active" : ""}`}><b>B</b></button>
          <button type="button" onClick={() => editor.chain().focus().toggleItalic().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("italic") ? "active" : ""}`}><i>I</i></button>
          <button type="button" onClick={() => editor.chain().focus().toggleHeading({ level: 1 }).run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("heading", { level: 1 }) ? "active" : ""}`}>H1</button>
          <button type="button" onClick={() => editor.chain().focus().toggleHeading({ level: 2 }).run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("heading", { level: 2 }) ? "active" : ""}`}>H2</button>
          <button type="button" onClick={() => editor.chain().focus().toggleBulletList().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("bulletList") ? "active" : ""}`}>• List</button>
          <button type="button" onClick={() => editor.chain().focus().toggleOrderedList().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("orderedList") ? "active" : ""}`}>1. List</button>
          <button type="button" onClick={() => editor.chain().focus().toggleBlockquote().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("blockquote") ? "active" : ""}`}>&gt; 引用</button>
          <button type="button" onClick={() => editor.chain().focus().toggleCodeBlock().run()} className={`btn btn-sm btn-outline-secondary ${editor.isActive("codeBlock") ? "active" : ""}`}>{"</>"}</button>
        </div>
      </BubbleMenu>
      <EditorContent editor={editor} className="w-100 ProseMirror" />
    </div>
  )
}

export default RichEditor