// confirm_modal_controller.ts
import { Controller } from "@hotwired/stimulus"
import { saveAndClose, discardChanges } from "../utils/memo_modal"

export default class ConfirmModalController extends Controller<HTMLElement> {
  static targets = ["modal"]
  declare readonly modalTarget: HTMLElement
  declare readonly hasModalTarget: boolean

  cancel(): void {
    const confirmModalEl = this.element
    const editorModalEl = document.getElementById("memoEditModal")
    if (!editorModalEl) return

    confirmModalEl.addEventListener(
      "hidden.bs.modal",
      () => {
        setTimeout(() => {
          document.querySelectorAll(".modal-backdrop").forEach((el) => el.remove())
          const editorModal = new (window as any).bootstrap.Modal(editorModalEl)
          editorModal.show()
        }, 10)
      },
      { once: true }
    )

    this.instance()?.hide()
  }

  discard(): void {
    discardChanges()
  }

  save(): void {
    saveAndClose()
  }

  instance(): bootstrap.Modal | null {
    return (window as any).bootstrap.Modal.getInstance(this.element) || null
  }
}