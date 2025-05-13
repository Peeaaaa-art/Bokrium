import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  connect() {
    this.setSlice()
    this.element.addEventListener("submit", this.setSlice.bind(this)) // ← フォーム送信前に実行
  }

  setSlice() {
    const isMobile = window.innerWidth <= 576
    const value = isMobile ? 5 : 10

    if (this.hasInputTarget) {
      this.inputTarget.value = value
    }
  }
}