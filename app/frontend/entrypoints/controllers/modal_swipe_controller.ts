import { Controller } from "@hotwired/stimulus"

export default class ModalSwipeController extends Controller<HTMLElement> {
  static targets = ["modal"]
  declare readonly modalTarget: HTMLElement

  private skipNextConfirmation = false

  connect() {
    this.modalTarget.addEventListener("hidden.bs.modal", this.onModalHidden)
    this.modalTarget.addEventListener("shown.bs.modal", () => {
      this.skipNextConfirmation = false
    })
  }

  disconnect() {
    this.modalTarget.removeEventListener("hidden.bs.modal", this.onModalHidden)
  }

  skipConfirmationOnce() {
    this.skipNextConfirmation = true
  }

  private onModalHidden = () => {
    if (this.skipNextConfirmation) {
      this.skipNextConfirmation = false
      return
    }

    if (window.hasUnsavedChanges) {
      const confirmModalEl = document.getElementById("confirmModal")
      if (confirmModalEl) {
        const confirm = new (window as any).bootstrap.Modal(confirmModalEl)
        confirm.show()
      }
    }
  }
}