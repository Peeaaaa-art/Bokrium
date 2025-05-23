import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select"]

  change() {
    this.element.requestSubmit()
  }
}