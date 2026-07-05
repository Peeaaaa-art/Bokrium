import { Controller } from "@hotwired/stimulus"

// テキストをクリップボードへコピーする(共有URLコピーなど)
export default class ClipboardController extends Controller<HTMLElement> {
  static values = {
    text: String,
    message: String,
  }

  declare readonly textValue: string
  declare readonly messageValue: string
  declare readonly hasMessageValue: boolean

  copy() {
    navigator.clipboard.writeText(this.textValue)
    if (this.hasMessageValue && this.messageValue) alert(this.messageValue)
  }
}
