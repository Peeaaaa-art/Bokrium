import { application } from "../application"

let isModalAnimating = false

function removeBackdrop(): void {
  document.querySelectorAll(".modal-backdrop").forEach((el) => el.remove())
}

function hideConfirmModal(callback?: () => void): void {
  const confirmModalEl = document.getElementById("confirmModal")
  const confirmInstance = (window as any).bootstrap?.Modal?.getInstance(confirmModalEl)

  if (confirmInstance && confirmModalEl) {
    confirmModalEl.addEventListener(
      "hidden.bs.modal",
      () => {
        removeBackdrop()
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

export function discardChanges(): void {
  if (isModalAnimating) return

  hideConfirmModal(() => {
    const modalEl = document.getElementById("memoEditModal")
    if (!modalEl) return

    const instance = (window as any).bootstrap?.Modal?.getInstance(modalEl)
    if (instance) {
      instance.hide()
    }

    const controller = application.getControllerForElementAndIdentifier(modalEl, "modal-swipe") as {
      skipConfirmationOnce?: () => void
    }

    controller?.skipConfirmationOnce?.()

    setTimeout(() => {
      removeBackdrop()
      const modal = (window as any).bootstrap?.Modal?.getOrCreateInstance(modalEl)
      modal?.hide()
      window.hasUnsavedChanges = false
    }, 200)
  })
}

export function saveAndClose(): void {
  if (isModalAnimating) return

  const form = document.getElementById("memo-edit-form") as HTMLFormElement | null
  if (form) form.requestSubmit()

  hideConfirmModal(() => {
    const modalEl = document.getElementById("memoEditModal")
    if (!modalEl) return

    const controller = application.getControllerForElementAndIdentifier(modalEl, "modal-swipe") as {
      skipConfirmationOnce?: () => void
    }
    controller?.skipConfirmationOnce?.()

    setTimeout(() => {
      removeBackdrop()
      const modal = (window as any).bootstrap?.Modal?.getOrCreateInstance(modalEl)
      modal?.hide()
      window.hasUnsavedChanges = false
    }, 200)
  })
}

;(window as any).returnToEditor = function () {
  if (isModalAnimating) return

  hideConfirmModal(() => {
    const editorModal = document.getElementById("memoEditModal")
    if (!editorModal) return

    const instance = (window as any).bootstrap?.Modal?.getInstance(editorModal)
    if (instance) instance.hide()

    setTimeout(() => {
      removeBackdrop()
      const newInstance = (window as any).bootstrap?.Modal?.getOrCreateInstance(editorModal)
      newInstance?.show()
    }, 200)
  })
}