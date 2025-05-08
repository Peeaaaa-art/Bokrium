import { Controller } from "@hotwired/stimulus"
import { mountRichEditor } from "../rich_editor"

export default class extends Controller {
  static values = {
    initialContent: String,
    memoId: String,
    bookId: String,
    createdAt: String,
    updatedAt: String
  }

  static targets = ["body", "icon"] // ← 表示トグル用

  connect() {
    console.log("🔌 memo-modal connected!")
    this.submitHandler = this.handleSubmit.bind(this)
    this.expanded = false
  }

  open(event) {
    document.activeElement?.blur?.() // iOS Safari 対策

    const trigger = event.currentTarget

    // データ取得
    const memoId = trigger.dataset.memoModalMemoIdValue
    const bookId = trigger.dataset.memoModalBookIdValue
    const createdAt = trigger.dataset.memoModalCreatedAtValue
    const updatedAt = trigger.dataset.memoModalUpdatedAtValue

    // HTMLから初期内容取得
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
      form.setAttribute("action", memoId === "new" ? `/books/${bookId}/memos` : `/books/${bookId}/memos/${memoId}`)
      form.setAttribute("method", "post")

      let methodInput = form.querySelector("input[name='_method']")
      if (memoId !== "new") {
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
      form.scrollIntoView({ behavior: 'smooth', block: 'center' })
    }

    // モーダルに作成日・更新日を表示
    const createdAtEl = document.getElementById("modal-created-at")
    const updatedAtEl = document.getElementById("modal-updated-at")
    if (createdAtEl && updatedAtEl) {
      createdAtEl.textContent = createdAt ? `作成日: ${createdAt}` : ""
      updatedAtEl.textContent = updatedAt ? `更新日: ${updatedAt}` : ""
    }

    // モーダル開く
    const modalElement = document.getElementById("memoEditModal")
    if (!modalElement) {
      console.error("❌ モーダルが見つかりません: memoEditModal")
      return
    }
    const modal = new bootstrap.Modal(modalElement)
    modal.show()
  }

  toggle(event) {
    event.stopPropagation()
    this.expanded = !this.expanded
    this.bodyTarget.classList.toggle("expanded", this.expanded)

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
