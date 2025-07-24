import { Controller } from "@hotwired/stimulus"

export default class SafariClickFixController extends Controller<HTMLElement> {
  connect() {
    setTimeout(() => {
      const elements = this.element.querySelectorAll<
        HTMLButtonElement | HTMLInputElement | HTMLAnchorElement
      >(
        ".safari-fix-button, button[type='submit'], input[type='submit'], a.btn, a.modal-action-button"
      )

      elements.forEach((el) => {
        if (document.activeElement === el) {
          (el as HTMLElement).blur()
        }
      })
    }, 100)
  }
}