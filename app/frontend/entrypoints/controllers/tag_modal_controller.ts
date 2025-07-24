import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

// モーダルを安全に切り替える Stimulus Controller（TypeScript対応）
export default class TagModalController extends Controller {
  static values = {
    targetId: String
  }

  declare readonly targetIdValue: string

  switch() {
    const currentModalEl = this.element.closest(".modal") as HTMLElement | null
    if (!currentModalEl) return

    const currentInstance = Modal.getInstance(currentModalEl)
    if (!currentInstance) return

    // 現在のモーダルが閉じられた後に次のモーダルを表示
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