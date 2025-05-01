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
  
    const contentElement = document.querySelector(`#memo-${memoId} .ProseMirror`)
    const content = contentElement?.innerHTML || ""
  
    console.log("📦 メモID:", memoId)
    console.log("📄 取得したHTMLコンテンツ:", content)
  
    // 🟢 ここで rich-editor-root に初期データを渡す
    const editorRoot = document.getElementById("rich-editor-root")
    if (editorRoot) {
      editorRoot.dataset.initialContent = content
      console.log("📝 エディタ初期化用の content をセットしました")
    } else {
      console.warn("⚠️ #rich-editor-root が見つかりませんでした")
    }

    const hiddenField = document.getElementById("memo_content_input")
    if (hiddenField) {
      hiddenField.value = content
      console.log("💾 hidden field に初期値をセットしました")
    } else {
      console.warn("⚠️ #memo_content_input が見つかりませんでした")
    }

    const form = document.getElementById("memo-edit-form")
    if (form) {
      form.setAttribute("action", `/books/${bookId}/memos/${memoId}`)
      console.log(`${form} の action を更新しました`)
    } else {
      console.warn("⚠️ #memo-edit-form が見つかりませんでした")
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
    } else {
      console.warn("⚠️ #memo-delete-button が見つかりませんでした")
    }

    // 🔽 最後にモーダル表示
    const modalElement = document.getElementById("memoEditModal")
    const modal = new bootstrap.Modal(modalElement)
    modal.show()
  }
}