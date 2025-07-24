import { Controller } from "@hotwired/stimulus"

export default class UiToggleController extends Controller {
  static targets = ["content"]

  declare readonly contentTarget: HTMLElement
  declare readonly hasContentTarget: boolean

  private isVisible = false

  connect() {
    this.hide()
  }

  toggle() {
    this.isVisible ? this.hide() : this.show()
  }

  show() {
    if (!this.hasContentTarget) return
    this.contentTarget.classList.add("show")
    this.contentTarget.hidden = false
    this.isVisible = true
  }

  hide() {
    if (!this.hasContentTarget) return
    this.contentTarget.classList.remove("show")
    this.contentTarget.hidden = true
    this.isVisible = false
  }
}