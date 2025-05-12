import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // 初期状態：非表示（念のため強制）
    this.contentTarget.classList.remove("show")
    this.isVisible = false
  }

  toggle() {
    this.isVisible = !this.isVisible
    this.contentTarget.classList.toggle("show", this.isVisible)
  }
}