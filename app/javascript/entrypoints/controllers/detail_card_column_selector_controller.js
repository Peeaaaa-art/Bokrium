import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selector"]

  change(event) {
    const cols = event.target.value

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