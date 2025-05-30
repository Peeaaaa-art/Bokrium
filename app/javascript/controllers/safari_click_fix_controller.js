// app/javascript/controllers/safari_click_fix_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    setTimeout(() => {
      const elements = this.element.querySelectorAll(
        ".safari-fix-button, button[type='submit'], input[type='submit'], a.btn, a.modal-action-button"
      )
      elements.forEach(el => {
        if (document.activeElement === el) {
          el.blur()
        }
      })
    }, 100)
  }
}