// app/javascript/controllers/modal_swipe_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.startY = null
    this.threshold = 330 // スワイプ距離の閾値（px）

    this.modalTarget.addEventListener("touchstart", this.onTouchStart)
    this.modalTarget.addEventListener("touchend", this.onTouchEnd)
  }

  disconnect() {
    this.modalTarget.removeEventListener("touchstart", this.onTouchStart)
    this.modalTarget.removeEventListener("touchend", this.onTouchEnd)
  }

  onTouchStart = (event) => {
    this.startY = event.touches[0].clientY
  }

  onTouchEnd = (event) => {
    const endY = event.changedTouches[0].clientY
    const deltaY = endY - this.startY

    if (Math.abs(deltaY) > this.threshold) {
      const modal = bootstrap.Modal.getInstance(this.modalTarget)

      if (deltaY > 0) {
        // 下にスワイプ → モーダルを閉じる
        modal?.hide()
      } else {
        // 上にスワイプ → ここに処理を追加可能
        console.log("上スワイプ detected")
        modal?.hide() // ここも一旦閉じるにしてますが、別処理OK
      }
    }

    this.startY = null
  }
}