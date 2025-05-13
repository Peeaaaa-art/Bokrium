// controllers/ui_toggle_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    this.hide()
  }

  toggle() {
    this.isVisible ? this.hide() : this.show()
  }

  show() {
    this.contentTarget.classList.add("show")
    this.contentTarget.hidden = false
    this.isVisible = true
  }

  hide() {
    this.contentTarget.classList.remove("show")
    this.contentTarget.hidden = true
    this.isVisible = false
  }
}