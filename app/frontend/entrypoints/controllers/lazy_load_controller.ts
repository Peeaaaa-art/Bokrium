import { Controller } from "@hotwired/stimulus"

export default class LazyLoadController extends Controller {
  static values = {
    url: String,
    frame: String,
  }

  declare readonly urlValue: string
  declare readonly frameValue: string
  private observer!: IntersectionObserver

  connect(): void {
    if ("IntersectionObserver" in window) {
      this.observer = new IntersectionObserver(
        (entries) => {
          if (entries[0].isIntersecting) {
            this.load()
          }
        },
        { threshold: 0.4 }
      )

      this.observer.observe(this.element)
    }
  }

  load(): void {
    if (this.urlValue && this.frameValue) {
      Turbo.visit(this.urlValue, { frame: this.frameValue })
      this.observer.disconnect()
    }
  }

  disconnect(): void {
    this.observer?.disconnect()
  }
}