import { Controller } from "@hotwired/stimulus"

export default class AutoSubmitController extends Controller {
  static targets = ["select"]

  declare readonly selectTarget: HTMLSelectElement

  change(_event: Event): void {
    (this.element as HTMLFormElement).requestSubmit()
  }
}