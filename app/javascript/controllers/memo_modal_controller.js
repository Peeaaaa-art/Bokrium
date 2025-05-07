import { Controller } from "@hotwired/stimulus"
import { mountRichEditor } from "../rich_editor"

export default class extends Controller {
  static values = {
    initialContent: String,
    memoId: String,
    bookId: String
  }

  static targets = ["body", "icon"] // ← 追加

  connect() {
    console.log("🔌 memo-modal connected!")
    this.submitHandler = this.handleSubmit.bind(this)
    this.expanded = false // ← 追加
  }

  open() {
    document.activeElement?.blur?.(); // iOS Safari対策

    const memoId = this.element.dataset.memoModalMemoIdValue
    const bookId = this.element.dataset.memoModalBookIdValue
    const isNew = memoId === "new"

    const contentElement = this.element.querySelector(".card-body")
    const contentHTML = contentElement?.innerHTML || ""
    const isPlaceholder = contentHTML.includes('PLACEHOLDER_TOKEN_9fz3!ifhdas094hfgfygq@_$2x')
    const initialContent = isPlaceholder ? "" : contentHTML

    const editorRoot = document.getElementById("rich-editor-root")
    if (editorRoot) {
      window.hasUnsavedChanges = false
      editorRoot.dataset.initialContent = initialContent
      editorRoot.dataset.memoId = memoId

      mountRichEditor(editorRoot)

      const observer = new MutationObserver(() => {
        const proseMirror = editorRoot.querySelector(".ProseMirror")
        if (proseMirror) {
          proseMirror.classList.add("editing")
          observer.disconnect()
        }
      })

      observer.observe(editorRoot, { childList: true, subtree: true })
    }

    const hiddenField = document.getElementById("memo_content_input")
    if (hiddenField) hiddenField.value = initialContent

    const form = document.getElementById("memo-edit-form")
    if (form) {
      form.setAttribute("action", isNew ? `/books/${bookId}/memos` : `/books/${bookId}/memos/${memoId}`)
      form.setAttribute("method", "post")

      let methodInput = form.querySelector("input[name='_method']")
      if (!isNew) {
        if (!methodInput) {
          methodInput = document.createElement("input")
          methodInput.type = "hidden"
          methodInput.name = "_method"
          form.appendChild(methodInput)
        }
        methodInput.value = "patch"
      } else {
        if (methodInput) methodInput.remove()
      }

      form.removeEventListener("submit", this.submitHandler)
      form.addEventListener("submit", this.submitHandler)
      form.scrollIntoView({ behavior: 'smooth', block: 'center' });
    }

    const modalElement = document.getElementById("memoEditModal")
    if (!modalElement) {
      console.error("❌ モーダルが見つかりません: memoEditModal")
      return
    }

    const modal = new bootstrap.Modal(modalElement)
    modal.show()
  }

  // ✅ 開閉トグル機能
  toggle(event) {
    event.stopPropagation()
    this.expanded = !this.expanded
    this.bodyTarget.classList.toggle("expanded", this.expanded)

    // アイコン切り替え
    this.iconTarget.classList.toggle("bi-arrows-angle-expand", !this.expanded)
    this.iconTarget.classList.toggle("bi-arrows-angle-contract", this.expanded)
  }

  handleSubmit() {
    const editorRoot = document.getElementById("rich-editor-root")
    const trailingBreaks = editorRoot?.querySelectorAll(".ProseMirror-trailingBreak")
    trailingBreaks?.forEach((br) => br.remove())

    const updatedContent = editorRoot?.querySelector(".ProseMirror")?.innerHTML || ""
    const hiddenField = document.getElementById("memo_content_input")
    if (hiddenField) hiddenField.value = updatedContent

    console.log("📜 フォーム送信直前: content =", updatedContent)
  }

  stop(event) {
    event.stopPropagation()
  }

  disconnect() {
    const editorRoot = document.getElementById("rich-editor-root")
    const proseMirror = editorRoot?.querySelector(".ProseMirror")
    if (proseMirror) {
      proseMirror.classList.remove("editing")
    }
  }
}