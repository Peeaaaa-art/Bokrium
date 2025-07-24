import { Controller } from "@hotwired/stimulus"

export default class AutoRemoveController extends Controller<HTMLElement> {
  connect(): void {
    setTimeout(() => {
      this.element.remove()
    }, 3000)
  }
}