import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class ModalSwipeController extends Controller<HTMLElement> {
  static targets = ["modal"]
  declare readonly modalTarget: HTMLElement

  private skipNextConfirmation = false

  connect() {
    this.modalTarget.addEventListener("hidden.bs.modal", this.onModalHidden)
    this.modalTarget.addEventListener("shown.bs.modal", this.onModalShown)
  }

  disconnect() {
    this.modalTarget.removeEventListener("hidden.bs.modal", this.onModalHidden)
    this.modalTarget.removeEventListener("shown.bs.modal", this.onModalShown)
  }

  skipConfirmationOnce() {
    this.skipNextConfirmation = true
  }

  private onModalShown = () => {
    this.skipNextConfirmation = false
  }

  private onModalHidden = () => {
    if (this.skipNextConfirmation) {
      this.skipNextConfirmation = false
      return
    }

    if (window.hasUnsavedChanges) {
      const confirmModalEl = document.getElementById("confirmModal")
      if (confirmModalEl) {
        const confirm = Modal.getOrCreateInstance(confirmModalEl)
        confirm.show()
      }
    }
  }
}
