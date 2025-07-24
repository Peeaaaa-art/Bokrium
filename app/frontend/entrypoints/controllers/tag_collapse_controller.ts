import { Controller } from "@hotwired/stimulus"

export default class TagCollapseController extends Controller<HTMLElement> {
  connect() {
    const collapses = this.element.querySelectorAll<HTMLElement>(".collapse")
    collapses.forEach((el) => el.classList.remove("show"))
  }
}