import { Controller } from "@hotwired/stimulus"

export default class ImageUploadController extends Controller {
  static targets = ["fileInput", "form"]

  declare readonly fileInputTarget: HTMLInputElement
  declare readonly formTarget: HTMLFormElement

  connect(): void {
    console.log("🖼 image upload controller connected")
  }

  triggerUpload(): void {
    const file = this.fileInputTarget.files?.[0]
    if (file) {
      this.formTarget.requestSubmit()
    }
  }
}