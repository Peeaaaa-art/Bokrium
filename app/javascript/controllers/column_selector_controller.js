import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selector", "grid"]

  connect() {
    this.defaultClass = this.gridTarget.className
  }

  change(event) {
    const cols = event.target.value
    this.gridTarget.className = this.defaultClass // reset

    if (cols) {
      this.gridTarget.classList.add(`cols-${cols}`)
    }
  }
}