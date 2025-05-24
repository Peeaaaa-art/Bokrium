import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selector", "grid"]

  connect() {
    this.defaultClass = this.gridTarget.className

    // 初期表示時に hiddenInput の値でクラス適用
    const hiddenInput = document.getElementById("hiddenColumnInput")
    if (hiddenInput && hiddenInput.value) {
      const cols = hiddenInput.value
      this.gridTarget.classList.add(`cols-${cols}`)
    }
  }

  change(event) {
    const cols = event.target.value

    this.gridTarget.className = this.defaultClass // reset
    this.gridTarget.classList.add(`cols-${cols}`)

    const hiddenInput = document.getElementById("hiddenColumnInput")
    if (hiddenInput) {
      hiddenInput.value = cols
    }
  }
}