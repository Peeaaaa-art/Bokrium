import { Controller } from "@hotwired/stimulus"
import { mountRichEditor } from "../rich_editor"

export default class extends Controller {
  static values = {
    initialContent: String,
    memoId: String,
    bookId: String
  }

  connect() {
    console.log("🔌 memo-modal connected!")
    this.submitHandler = this.handleSubmit.bind(this)
  }

  open(event) {
    document.activeElement?.blur?.(); // iOS Safari対策

    const memoId = this.element.dataset.memoModalMemoIdValue
    const bookId = this.element.dataset.memoModalBookIdValue
    const isNew = memoId === "new"

    const contentElement = this.element.querySelector(".card-body")
    const contentHTML = contentElement?.innerHTML || ""
    const isPlaceholder = contentHTML.includes('PLACEHOLDER_TOKEN_9fz3!ifhdas094hfgfygq@_$2x')
    const initialContent = isPlaceholder ? "" : contentHTML

    // リッチエディタ初期化
    const editorRoot = document.getElementById("rich-editor-root")
    if (editorRoot) {
      window.hasUnsavedChanges = false
      editorRoot.dataset.initialContent = initialContent
      editorRoot.dataset.memoId = memoId
      mountRichEditor(editorRoot)
    }

    // hidden input 更新
    const hiddenField = document.getElementById("memo_content_input")
    if (hiddenField) hiddenField.value = initialContent

    // フォーム構成
    const form = document.getElementById("memo-edit-form")
    if (form) {
      form.setAttribute("action", isNew ? `/books/${bookId}/memos` : `/books/${bookId}/memos/${memoId}`)
      form.setAttribute("method", "post")

      // _method hidden field を動的に設定
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

      // 古い submitHandler を削除し、再登録
      form.removeEventListener("submit", this.submitHandler)
      form.addEventListener("submit", this.submitHandler)
    }

    // モーダル表示
    const modalElement = document.getElementById("memoEditModal")
    if (!modalElement) {
      console.error("❌ モーダルが見つかりません: memoEditModal")
      return
    }

    const modal = new bootstrap.Modal(modalElement)
    modal.show()
  }

  handleSubmit(event) {
    // submit直前処理：エディタ内容をhiddenに格納
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
}