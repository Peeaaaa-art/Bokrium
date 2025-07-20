import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "form"]

  connect() {
    console.log("🖼 image upload controller connected")
  }

  triggerUpload() {
    const file = this.fileInputTarget.files[0]
    if (file) {
      this.formTarget.requestSubmit()
    }
  }
}