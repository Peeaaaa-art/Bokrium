// controllers/responsive_slice_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "selector"]

  connect() {
    if (!this.hasSelectorTarget || this.selectorTarget.value === "") {
      const width = window.innerWidth
      let booksPerRow = 12

      if (width < 576) {
        booksPerRow = 5
      } else if (width < 900) {
        booksPerRow = 10
      }

      this.inputTarget.value = booksPerRow
    } else {
      this.inputTarget.value = this.selectorTarget.value
    }
  }

  userSelected(event) {
    this.inputTarget.value = event.target.value
    this.element.requestSubmit() // 💡 自動で再検索
  }
}