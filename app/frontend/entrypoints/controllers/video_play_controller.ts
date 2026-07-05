import { Controller } from "@hotwired/stimulus"

// ポスター上の再生ボタン。クリックで動画を再生してボタンを隠す
export default class VideoPlayController extends Controller<HTMLElement> {
  static targets = ["video", "button"]

  declare readonly videoTarget: HTMLVideoElement
  declare readonly buttonTarget: HTMLElement

  play() {
    this.videoTarget.play()
    this.buttonTarget.style.display = "none"
  }
}
