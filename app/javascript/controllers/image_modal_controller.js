import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.initializeModals();
  }

  initializeModals() {
    const modals = this.element.querySelectorAll('.modal');
    modals.forEach((modal) => {
      // モーダルがまだ初期化されてない場合だけ実行
      if (!modal.dataset.bsModal) {
        new bootstrap.Modal(modal);
      }
    });
  }
}