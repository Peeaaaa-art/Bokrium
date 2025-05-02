import { Controller } from "@hotwired/stimulus"
import { mountRichEditor } from "../rich_editor"

export default class extends Controller {
  connect() {
    console.log("🔌 memo-modal connected!")

    const memoId = this.element.dataset.memoModalMemoIdValue
    const bookId = this.element.dataset.memoModalBookIdValue

    console.log("📦 memoId =", memoId)
    console.log("📘 bookId =", bookId)
  }

  open(event) {
    console.log("✅ モーダルを開こうとしています")

    const memoId = this.element.dataset.memoModalMemoIdValue
    const bookId = this.element.dataset.memoModalBookIdValue
    const isNew = memoId === "new";
    const contentElement = document.querySelector(`#memo-${memoId} .ProseMirror`)
    const content = contentElement?.innerHTML || ""

    console.log("📄 取得したHTMLコンテンツ:", content)

    const editorRoot = document.getElementById("rich-editor-root")
    if (editorRoot) {
      editorRoot.dataset.initialContent = content
      editorRoot.dataset.memoId = memoId
      mountRichEditor(editorRoot)
    }

    const hiddenField = document.getElementById("memo_content_input")
    if (hiddenField) hiddenField.value = content

    const form = document.getElementById("memo-edit-form")
    if (form) {
      if (isNew) {
        form.setAttribute("action", `/books/${bookId}/memos`)
        form.setAttribute("method", "post")
      } else {
        form.setAttribute("action", `/books/${bookId}/memos/${memoId}`)
        form.setAttribute("method", "post") // PATCHをエミュレート
      }
    
      form.addEventListener("submit", () => {
        const editorRoot = document.getElementById("rich-editor-root")
        const content = editorRoot?.querySelector(".ProseMirror")?.innerHTML || ""
        const hiddenField = document.getElementById("memo_content_input")
        if (hiddenField) {
          hiddenField.value = content
          console.log("📝 フォーム送信直前に hidden input を更新:", content)
        }
      }, { once: true })
    }

    const deleteButton = document.getElementById("memo-delete-button")
    if (deleteButton) {
      deleteButton.onclick = () => {
        if (confirm("本当に削除しますか？")) {
          fetch(`/books/${bookId}/memos/${memoId}`, {
            method: "DELETE",
            headers: {
              "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
            }
          }).then(() => {
            console.log("🗑 メモを削除しました。ページをリロードします")
            location.reload()
          })
        }
      }
    }

    const modalElement = document.getElementById("memoEditModal")
    const modal = new bootstrap.Modal(modalElement)
    modal.show()
  }
}