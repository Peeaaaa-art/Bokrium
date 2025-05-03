import { Controller } from "@hotwired/stimulus"
import { mountRichEditor } from "../rich_editor"

export default class extends Controller {
  connect() {
    console.log("🔌 memo-modal connected!")
  }

  open(event) {
    const memoId = this.element.dataset.memoModalMemoIdValue
    const bookId = this.element.dataset.memoModalBookIdValue
    const isNew = memoId === "new"

    // 表示中のHTMLから content を取得
    const contentElement = document.querySelector(`#memo-${memoId} .ProseMirror`)
    const content = contentElement?.innerHTML || ""

    // エディタ初期化
    const editorRoot = document.getElementById("rich-editor-root")
    if (editorRoot) {
      editorRoot.dataset.initialContent = content
      editorRoot.dataset.memoId = memoId
      mountRichEditor(editorRoot)
    }

    // hidden content input を更新
    const hiddenField = document.getElementById("memo_content_input")
    if (hiddenField) hiddenField.value = content

    // フォーム設定
    const form = document.getElementById("memo-edit-form")
    if (form) {
      form.setAttribute("action", isNew ? `/books/${bookId}/memos` : `/books/${bookId}/memos/${memoId}`)
      form.setAttribute("method", "post")

      // PATCH の hidden input を追加または削除
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

      // submit 時に content を hidden input にセット
      form.addEventListener("submit", () => {
        const updatedContent = editorRoot?.querySelector(".ProseMirror")?.innerHTML || ""
        if (hiddenField) hiddenField.value = updatedContent
        console.log("📝 フォーム送信直前: content =", updatedContent)
      }, { once: true })
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

  stop(event) {
    event.stopPropagation()
  }
}