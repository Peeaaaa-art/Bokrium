import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selector", "grid"]

  connect() {
    this.defaultClass = this.gridTarget.className

    const hiddenInput = document.getElementById("hiddenColumnInput")
    if (hiddenInput && hiddenInput.value) {
      const cols = hiddenInput.value
      this.gridTarget.classList.add(`cols-${cols}`)
    }
  }

  change(event) {
    const cols = event.target.value

    this.gridTarget.className = this.defaultClass
    this.gridTarget.classList.add(`cols-${cols}`)

    const hiddenInput = document.getElementById("hiddenColumnInput")
    if (hiddenInput) {
      hiddenInput.value = cols
    }

    const form = document.getElementById("columnForm")
    if (form) {
      form.requestSubmit()
    }
  }
}