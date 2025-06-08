import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    frame: String
  }

  connect() {
    if ("IntersectionObserver" in window) {
      this.observer = new IntersectionObserver(entries => {
        if (entries[0].isIntersecting) {
          this.load()
        }
      }, { threshold: 0.4 })

      this.observer.observe(this.element)
    }
  }

  load() {
    if (this.urlValue && this.frameValue) {
      Turbo.visit(this.urlValue, { frame: this.frameValue })
      this.observer.disconnect()
    }
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}