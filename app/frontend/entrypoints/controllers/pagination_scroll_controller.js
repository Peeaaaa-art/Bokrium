import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("click", (event) => {
      const target = event.target.closest("a");
      if (target && target.href && !target.hasAttribute("data-no-scroll")) {
        // ページネーションリンククリック時
        setTimeout(() => {
          window.scrollTo(0, 0);
        }, 10); // Turbo等の遷移後に発火させるため少し遅延
      }
    });
  }
}
