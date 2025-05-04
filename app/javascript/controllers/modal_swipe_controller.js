import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.startY = null
    this.threshold = 280
    this.skipNextConfirmation = false

    this.modalTarget.addEventListener("touchstart", this.onTouchStart)
    this.modalTarget.addEventListener("touchend", this.onTouchEnd)
    this.modalTarget.addEventListener("hidden.bs.modal", this.onModalHidden)

    this.modalTarget.addEventListener("shown.bs.modal", () => {
      this.skipNextConfirmation = false
    })
  }

  disconnect() {
    this.modalTarget.removeEventListener("touchstart", this.onTouchStart)
    this.modalTarget.removeEventListener("touchend", this.onTouchEnd)
    this.modalTarget.removeEventListener("hidden.bs.modal", this.onModalHidden)
  }

  skipConfirmationOnce() {
    this.skipNextConfirmation = true
  }

  onTouchStart = (e) => {
    this.startY = e.touches[0].clientY
  }

  onTouchEnd = (e) => {
    const endY = e.changedTouches[0].clientY
    const deltaY = endY - this.startY

    if (Math.abs(deltaY) > this.threshold) {
      if (window.hasUnsavedChanges) {
        this.shouldShowConfirmOnClose = true
      }
      bootstrap.Modal.getInstance(this.modalTarget)?.hide()
    }

    this.startY = null
  }

  onModalHidden = () => {
    if (this.skipNextConfirmation) {
      this.skipNextConfirmation = false
      return
    }

    if (window.hasUnsavedChanges || this.shouldShowConfirmOnClose) {
      this.shouldShowConfirmOnClose = false
      const confirm = new bootstrap.Modal(document.getElementById("confirmModal"))
      confirm.show()
    }
  }
}