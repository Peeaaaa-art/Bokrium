// app/javascript/controllers/confirm_modal_controller.js
import { Controller } from "@hotwired/stimulus"
import { saveAndClose, discardChanges } from "../utils/memo_modal" 

export default class extends Controller {
  static targets = ["modal"]

  cancel() {
    const confirmModalEl = this.element
    const editorModalEl = document.getElementById("memoEditModal")
    if (!editorModalEl) return
  
    confirmModalEl.addEventListener("hidden.bs.modal", () => {
      setTimeout(() => {
        document.querySelectorAll(".modal-backdrop").forEach(el => el.remove())
        const editorModal = new bootstrap.Modal(editorModalEl)
        editorModal.show()
      }, 10)
    }, { once: true })
  
    this.instance().hide()
  }

  discard() {
    discardChanges()
  }

  save() {
    saveAndClose()
  }

  instance() {
    return bootstrap.Modal.getInstance(this.element)
  }
}