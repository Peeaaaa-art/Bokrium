import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String
  }

  connect() {
    if ("IntersectionObserver" in window) {
      this.observer = new IntersectionObserver(entries => {
        if (entries[0].isIntersecting) {
          this.loadMore()
        }
      })
      this.observer.observe(this.element)
    }
  }

  loadMore() {
    if (this.urlValue) {
      this.element.innerHTML = `
        <div class="text-center my-4">
          <div class="spinner-border text-primary-bok opacity-25" role="status"></div>
        </div>
      `
      Turbo.visit(this.urlValue, { frame: "books_frame" })
    }
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}