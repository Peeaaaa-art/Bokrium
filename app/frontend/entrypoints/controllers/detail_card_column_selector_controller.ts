import { Controller } from "@hotwired/stimulus"

export default class DetailCardColumnSelectorController extends Controller {
  static targets = ["selector"]
  declare readonly selectorTarget: HTMLSelectElement

  change(event: Event) {
    const target = event.target as HTMLSelectElement
    const cols = target.value

    const hiddenInput = document.getElementById("hiddenColumnInput") as HTMLInputElement | null
    if (hiddenInput) {
      hiddenInput.value = cols
    }

    const form = document.getElementById("columnForm") as HTMLFormElement | null
    if (form) {
      form.requestSubmit()
    }
  }
}