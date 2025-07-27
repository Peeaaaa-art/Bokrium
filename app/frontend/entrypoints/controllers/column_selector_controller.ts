import { Controller } from "@hotwired/stimulus"

export default class ColumnSelectorController extends Controller {
  static targets = ["selector"]

  change(event: Event) {
    const target = event.target as HTMLSelectElement
    const cols = target.value

    // hidden inputの更新
    const hiddenInput = document.getElementById("hiddenColumnInput") as HTMLInputElement | null
    if (hiddenInput) {
      hiddenInput.value = cols
    }

    // フォーム送信
    const form = document.getElementById("columnForm") as HTMLFormElement | null
    if (form) {
      form.requestSubmit()
    }
  }
}