import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="spinner"
export default class extends Controller {
  connect() {
    this.showSpinner = this.showSpinner.bind(this);
    this.hideSpinner = this.hideSpinner.bind(this);

    document.addEventListener('turbo:submit-start', this.showSpinner);
    document.addEventListener('turbo:submit-end', this.hideSpinner);
  }

  disconnect() {
    document.removeEventListener('turbo:submit-start', this.showSpinner);
    document.removeEventListener('turbo:submit-end', this.hideSpinner);
  }

  showSpinner() {
    document.getElementById('loading-spinner').classList.remove('d-none');
  }

  hideSpinner() {
    document.getElementById('loading-spinner').classList.add('d-none');
  }
}