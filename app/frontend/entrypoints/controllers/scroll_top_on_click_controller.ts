import { Controller } from "@hotwired/stimulus"

export default class ScrollTopOnClickController extends Controller<HTMLElement> {
  connect(): void {
    this.element.addEventListener("click", (event: MouseEvent) => {
      const target = (event.target as HTMLElement)?.closest("a") as HTMLAnchorElement | null

      if (target && target.href && !target.hasAttribute("data-no-scroll")) {
        // Turbo などによるページ遷移後にスクロール位置をトップに戻す
        setTimeout(() => {
          window.scrollTo(0, 0)
        }, 10)
      }
    })
  }
}