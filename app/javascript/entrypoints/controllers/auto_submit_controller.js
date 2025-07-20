// auto_submit_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  change(event) {
    this.element.requestSubmit()
  }
}