import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.style.overflow = 'hidden'
    this.grow()
    this.element.addEventListener('input', this.grow.bind(this))
  }

  grow() {
    this.element.style.height = 'auto'
    this.element.style.height = `${this.element.scrollHeight}px`
  }
}
