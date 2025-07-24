import { Controller } from "@hotwired/stimulus"

export default class ColumnSelectorController extends Controller {
  static targets = ["selector", "grid"]

  declare readonly gridTarget: HTMLElement
  declare readonly hasGridTarget: boolean

  private defaultClass: string = ""

  connect() {
    this.defaultClass = this.gridTarget.className

    const hiddenInput = document.getElementById("hiddenColumnInput") as HTMLInputElement | null
    if (hiddenInput?.value) {
      const cols = hiddenInput.value
      this.gridTarget.classList.add(`cols-${cols}`)
    }
  }

  change(event: Event) {
    const target = event.target as HTMLSelectElement
    const cols = target.value

    this.gridTarget.className = this.defaultClass
    this.gridTarget.classList.add(`cols-${cols}`)

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