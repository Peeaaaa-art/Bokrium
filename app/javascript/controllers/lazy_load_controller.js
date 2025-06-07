// app/javascript/controllers/lazy_load_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    frame: String
  }

  connect() {
    if (!("IntersectionObserver" in window)) return

    this.observer = new IntersectionObserver(entries => {
      if (entries[0].isIntersecting) {
        this.loadContent()
        this.observer.disconnect()
      }
    }, { threshold: 0.3 })

    this.observer.observe(this.element)
  }

  loadContent() {
    Turbo.visit(this.urlValue, {
      frame: this.frameValue
    })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}