import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

// モーダルを安全に切り替える Stimulus controller
export default class extends Controller {
  static values = {
    targetId: String // 開きたいモーダルの ID を受け取る
  }

  switch() {
    const currentModalEl = this.element.closest(".modal")
    const currentInstance = Modal.getInstance(currentModalEl)

    if (currentInstance) {
      // 現在のモーダルを閉じた後、新しいモーダルを開く
      currentModalEl.addEventListener(
        "hidden.bs.modal",
        () => {
          const nextModal = document.getElementById(this.targetIdValue)
          if (nextModal) {
            const newModal = new Modal(nextModal)
            newModal.show()
          }
        },
        { once: true }
      )
      currentInstance.hide()
    }
  }
}