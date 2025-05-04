// ✅ app/javascript/utils/memo_modal.js
import { application } from "../application"

function hideConfirmModal(callback) {
  const confirmModalEl = document.getElementById("confirmModal")
  const confirmInstance = bootstrap.Modal.getInstance(confirmModalEl)

  if (confirmInstance) {
    confirmModalEl.addEventListener("hidden.bs.modal", () => {
      // 🔧 スマホ対策: モーダル非表示後、少し遅らせて実行
      setTimeout(() => {
        callback?.()
      }, 150)
    }, { once: true })

    confirmInstance.hide()
  } else {
    callback?.()
  }
}

export function discardChanges() {
  hideConfirmModal(() => {
    const modalEl = document.getElementById("memoEditModal")
    const controller = application.getControllerForElementAndIdentifier(modalEl, "modal-swipe")
    controller?.skipConfirmationOnce?.()

    bootstrap.Modal.getInstance(modalEl)?.hide()
    window.hasUnsavedChanges = false
  })
}

export function saveAndClose() {
  const form = document.getElementById("memo-edit-form")
  if (form) form.requestSubmit()

  hideConfirmModal(() => {
    const modalEl = document.getElementById("memoEditModal")
    const controller = application.getControllerForElementAndIdentifier(modalEl, "modal-swipe")
    controller?.skipConfirmationOnce?.()

    bootstrap.Modal.getInstance(modalEl)?.hide()
    window.hasUnsavedChanges = false
  })
}

// ✅ エディタに戻る（キャンセル）
window.returnToEditor = function () {
  hideConfirmModal(() => {
    const editorModal = new bootstrap.Modal(document.getElementById("memoEditModal"))
    editorModal.show()
  })
}