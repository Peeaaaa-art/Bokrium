// modal_swipe_controller
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal"]

  connect() {
    this.startY = null
    this.threshold = 300

    this.modalTarget.addEventListener("touchstart", this.onTouchStart)
    this.modalTarget.addEventListener("touchend", this.onTouchEnd)
  }

  disconnect() {
    this.modalTarget.removeEventListener("touchstart", this.onTouchStart)
    this.modalTarget.removeEventListener("touchend", this.onTouchEnd)
  }

  onTouchStart = (e) => {
    this.startY = e.touches[0].clientY
  }

  onTouchEnd = (e) => {
    const endY = e.changedTouches[0].clientY
    const deltaY = endY - this.startY
  
    console.log("🧪 スワイプ距離:", deltaY)
    console.log("🧪 window.hasUnsavedChanges:", window.hasUnsavedChanges)
  
    if (Math.abs(deltaY) > this.threshold) {
      if (window.hasUnsavedChanges) {
        console.log("⚠️ 変更あり → 確認モーダル表示")
        const editorModalEl = document.getElementById("memoEditModal")
        const editorModal = bootstrap.Modal.getInstance(editorModalEl)
        editorModal?.hide()
  
        editorModalEl.addEventListener("hidden.bs.modal", () => {
          const confirm = new bootstrap.Modal(document.getElementById("confirmModal"))
          confirm.show()
        }, { once: true })
      } else {
        console.log("✅ 変更なし → 通常閉じ")
        bootstrap.Modal.getInstance(this.modalTarget)?.hide()
      }
    }
  
    this.startY = null
  }
}