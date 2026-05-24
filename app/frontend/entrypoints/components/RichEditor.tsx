// =========================
// RichEditor (編集用)
// =========================
import { useEffect, useState } from "react"
import type { ReactElement } from "react"
import { useEditor, EditorContent, BubbleMenu } from "@tiptap/react"
import StarterKit from "@tiptap/starter-kit"
import BubbleMenuExtension from "@tiptap/extension-bubble-menu"
import CharacterCount from "@tiptap/extension-character-count"
import { getMarkRange } from "@tiptap/core"
import {
  createMemoLinkExtension,
  MarkdownLinkInputExtension,
  normalizeSafeMemoUrl,
  prepareMemoHtmlForSave,
} from "../utils/memo_links"
import { MarkdownPasteExtension } from "../utils/markdown_paste"
import { normalizeProseMirrorHtmlForSave } from "../utils/prosemirror_html"

interface RichEditorProps {
  element: HTMLElement
}

const decodeHTML = (html: string): string => {
  const textarea = document.createElement("textarea")
  textarea.innerHTML = html
  return textarea.value
}

function RichEditor({ element }: RichEditorProps): ReactElement | null {
  const initialRaw = element.dataset.initialContent ?? ""
  const inputId = element.dataset.inputId ?? "memo_content_input"
  const initialContent = prepareMemoHtmlForSave(decodeHTML(initialRaw))
  const [linkFormOpen, setLinkFormOpen] = useState(false)
  const [linkLabel, setLinkLabel] = useState("")
  const [linkUrl, setLinkUrl] = useState("")
  const [linkError, setLinkError] = useState("")
  const [linkRange, setLinkRange] = useState<{ from: number; to: number } | null>(null)

  const editor = useEditor({
    extensions: [
      StarterKit,
      MarkdownPasteExtension,
      MarkdownLinkInputExtension,
      createMemoLinkExtension(false),
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

    let previousHTML = prepareMemoHtmlForSave(normalizeProseMirrorHtmlForSave(editor.getHTML()))
    if (hiddenField) hiddenField.value = previousHTML

    if (saveButton) {
      saveButton.disabled = true
      saveButton.classList.add("disabled")
    }

    const updateHandler = () => {
      const currentHTML = prepareMemoHtmlForSave(normalizeProseMirrorHtmlForSave(editor.getHTML()))

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

  const getCurrentLinkRange = () => {
    const linkMark = editor.schema.marks.link
    if (!linkMark) return null

    return getMarkRange(editor.state.selection.$from, linkMark)
  }

  const selectedText = () => {
    const { from, to, empty } = editor.state.selection
    if (empty) return ""

    return editor.state.doc.textBetween(from, to, "\n")
  }

  const openLinkForm = () => {
    const range = getCurrentLinkRange()
    const selection = editor.state.selection
    const href = editor.getAttributes("link").href as string | undefined

    setLinkLabel(range ? editor.state.doc.textBetween(range.from, range.to, "\n") : selectedText())
    setLinkUrl(href ?? "")
    setLinkError("")
    setLinkRange(range ?? { from: selection.from, to: selection.to })
    setLinkFormOpen(true)
  }

  const applyLink = () => {
    const label = linkLabel.trim()
    const safeUrl = normalizeSafeMemoUrl(linkUrl)

    if (!label || !safeUrl) {
      setLinkError("表示名とURLを入力してください")
      return
    }

    const range = linkRange ?? getCurrentLinkRange() ?? editor.state.selection
    editor
      .chain()
      .focus()
      .setTextSelection({ from: range.from, to: range.to })
      .insertContent({
        type: "text",
        text: label,
        marks: [{ type: "link", attrs: { href: safeUrl } }],
      })
      .run()

    setLinkFormOpen(false)
    setLinkError("")
    setLinkRange(null)
  }

  const removeLink = () => {
    if (linkRange) {
      editor.chain().focus().setTextSelection(linkRange).unsetLink().run()
    } else {
      editor.chain().focus().extendMarkRange("link").unsetLink().run()
    }
    setLinkFormOpen(false)
    setLinkError("")
    setLinkRange(null)
  }

  return (
    <div className="rhodia-grid-bg" style={{ overflowY: "auto", position: "relative" }}>
      <BubbleMenu
        editor={editor}
        tippyOptions={{ duration: 150, interactive: true }}
        shouldShow={({ editor }) => linkFormOpen || editor.isActive("link") || !editor.state.selection.empty}
      >
        <div className="bubble-menu bg-white border rounded shadow-sm p-2">
          <div className="d-flex flex-wrap gap-2">
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
            <button
              type="button"
              onMouseDown={(event) => {
                event.preventDefault()
                openLinkForm()
              }}
              className={`btn btn-sm btn-outline-secondary ${editor.isActive("link") ? "active" : ""}`}
              title="リンクを編集"
            >
              リンク
            </button>
          </div>

          {linkFormOpen && (
            <div className="d-flex flex-column gap-2 mt-2" style={{ width: "min(72vw, 320px)" }}>
              <input
                type="text"
                className="form-control form-control-sm"
                value={linkLabel}
                onChange={(event) => setLinkLabel(event.currentTarget.value)}
                placeholder="表示名"
                aria-label="リンクの表示名"
              />
              <input
                type="url"
                className="form-control form-control-sm"
                value={linkUrl}
                onChange={(event) => setLinkUrl(event.currentTarget.value)}
                placeholder="https://example.com"
                aria-label="リンクURL"
              />
              {linkError && <div className="small text-danger">{linkError}</div>}
              <div className="d-flex gap-2 justify-content-end">
                {editor.isActive("link") && (
                  <button type="button" className="btn btn-sm btn-outline-danger" onClick={removeLink}>
                    解除
                  </button>
                )}
                <button type="button" className="btn btn-sm btn-outline-secondary" onClick={() => {
                  setLinkFormOpen(false)
                  setLinkRange(null)
                }}>
                  閉じる
                </button>
                <button type="button" className="btn btn-sm btn-primary" onClick={applyLink}>
                  適用
                </button>
              </div>
            </div>
          )}
        </div>
      </BubbleMenu>
      <EditorContent editor={editor} className="w-100 ProseMirror" />
    </div>
  )
}

export default RichEditor
