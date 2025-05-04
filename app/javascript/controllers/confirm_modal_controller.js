// app/javascript/controllers/confirm_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  cancel() {
    this.instance().hide()

    const editorModalEl = document.getElementById("memoEditModal")
    if (editorModalEl) {
      const editorModal = new bootstrap.Modal(editorModalEl)
      editorModal.show()
    }
  }

  discard() {
    this.dispatch("discard") // イベントを送る
    this.instance().hide()
  }

  save() {
    this.dispatch("save")
    this.instance().hide()
  }

  instance() {
    return bootstrap.Modal.getInstance(this.element)
  }
}