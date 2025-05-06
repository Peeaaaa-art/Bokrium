import { application } from "../application"

let isModalAnimating = false

function removeBackdrop() {
  document.querySelectorAll(".modal-backdrop").forEach((el) => el.remove())
}

// メモ：背景黒が重なる不具合に対応するため、以下の対策を実施：
// - .modal-backdrop 削除
// - モーダルアニメーション中の二重開閉禁止
// - Safariの描画バグ回避（setTimeout）
// 変更前コードでスマホSafariにて不具合があったため、このまま維持する
function hideConfirmModal(callback) {
  const confirmModalEl = document.getElementById("confirmModal")
  const confirmInstance = bootstrap.Modal.getInstance(confirmModalEl)

  if (confirmInstance) {
    confirmModalEl.addEventListener(
      "hidden.bs.modal",
      () => {
        // 💡 確実にbackdrop削除
        removeBackdrop()

        // 💡 再度モーダル表示がある場合に備え、非同期で処理継続
        setTimeout(() => {
          isModalAnimating = false
          callback?.()
        }, 200)
      },
      { once: true }
    )

    isModalAnimating = true
    confirmInstance.hide()
  } else {
    removeBackdrop()
    isModalAnimating = false
    callback?.()
  }
}

export function discardChanges() {
  if (isModalAnimating) return

  hideConfirmModal(() => {
    const modalEl = document.getElementById("memoEditModal")

    // 💡 現在表示中のモーダルを強制的に閉じて再表示の競合を避ける
    const instance = bootstrap.Modal.getInstance(modalEl)
    if (instance) {
      instance.hide()
    }

    const controller = application.getControllerForElementAndIdentifier(modalEl, "modal-swipe")
    controller?.skipConfirmationOnce?.()

    setTimeout(() => {
      removeBackdrop()
      bootstrap.Modal.getOrCreateInstance(modalEl).hide()
      window.hasUnsavedChanges = false
    }, 200)
  })
}

export function saveAndClose() {
  if (isModalAnimating) return

  const form = document.getElementById("memo-edit-form")
  if (form) form.requestSubmit()

  hideConfirmModal(() => {
    const modalEl = document.getElementById("memoEditModal")
    const controller = application.getControllerForElementAndIdentifier(modalEl, "modal-swipe")
    controller?.skipConfirmationOnce?.()

    setTimeout(() => {
      removeBackdrop()
      bootstrap.Modal.getOrCreateInstance(modalEl).hide()
      window.hasUnsavedChanges = false
    }, 200)
  })
}

window.returnToEditor = function () {
  if (isModalAnimating) return

  hideConfirmModal(() => {
    const editorModal = document.getElementById("memoEditModal")

    // 💡 表示中のモーダルがあれば一度閉じる
    const instance = bootstrap.Modal.getInstance(editorModal)
    if (instance) instance.hide()

    setTimeout(() => {
      removeBackdrop()
      const newInstance = bootstrap.Modal.getOrCreateInstance(editorModal)
      newInstance.show()
    }, 200)
  })
}