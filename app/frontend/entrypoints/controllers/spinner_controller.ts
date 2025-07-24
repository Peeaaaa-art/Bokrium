import { Controller } from "@hotwired/stimulus"

export default class SpinnerController extends Controller {
  private showSpinner = () => {}
  private hideSpinner = () => {}

  connect() {
    this.showSpinner = this._showSpinner.bind(this)
    this.hideSpinner = this._hideSpinner.bind(this)

    document.addEventListener("turbo:submit-start", this.showSpinner)
    document.addEventListener("turbo:submit-end", this.hideSpinner)
  }

  disconnect() {
    document.removeEventListener("turbo:submit-start", this.showSpinner)
    document.removeEventListener("turbo:submit-end", this.hideSpinner)
  }

  private _showSpinner() {
    const spinner = document.getElementById("loading-spinner")
    if (spinner) spinner.classList.remove("d-none")
  }

  private _hideSpinner() {
    const spinner = document.getElementById("loading-spinner")
    if (spinner) spinner.classList.add("d-none")
  }
}