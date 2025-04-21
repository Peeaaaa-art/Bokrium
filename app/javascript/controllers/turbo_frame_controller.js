import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  removeForm(event) {
    event.preventDefault()
    this.element.closest('.card').remove()
  }
}
