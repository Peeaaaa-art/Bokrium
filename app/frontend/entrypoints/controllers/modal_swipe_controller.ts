import { Controller } from "@hotwired/stimulus"

export default class ModalSwipeController extends Controller<HTMLElement> {
  static targets = ["modal"]
  declare readonly modalTarget: HTMLElement

  private startY: number | null = null
  private threshold = 250
  private skipNextConfirmation = false
  private shouldShowConfirmOnClose = false

  connect() {
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

  private onTouchStart = (e: TouchEvent) => {
    this.startY = e.touches[0]?.clientY ?? null
  }

  private onTouchEnd = (e: TouchEvent) => {
    const endY = e.changedTouches[0]?.clientY ?? 0
    const deltaY = this.startY !== null ? endY - this.startY : 0

    if (Math.abs(deltaY) > this.threshold) {
      if (window.hasUnsavedChanges) {
        this.shouldShowConfirmOnClose = true
      }
      (window as any).bootstrap.Modal.getInstance(this.modalTarget)?.hide()
    }

    this.startY = null
  }

  private onModalHidden = () => {
    if (this.skipNextConfirmation) {
      this.skipNextConfirmation = false
      return
    }

    if (window.hasUnsavedChanges || this.shouldShowConfirmOnClose) {
      this.shouldShowConfirmOnClose = false
      const confirmModalEl = document.getElementById("confirmModal")
      if (confirmModalEl) {
        const confirm = new (window as any).bootstrap.Modal(confirmModalEl)
        confirm.show()
      }
    }
  }
}