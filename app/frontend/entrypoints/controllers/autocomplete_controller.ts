import { Controller } from "@hotwired/stimulus"

export default class AutocompleteController extends Controller {
  static targets = ["input"]

  private searchTimer: number | null = null

  connect(): void {
    this.searchTimer = null
  }

  disconnect(): void {
    if (this.searchTimer) clearTimeout(this.searchTimer)
  }

  search(_event: Event): void {
    this.scheduleBookshelfSearch()
  }

  private scheduleBookshelfSearch(): void {
    if (this.searchTimer) clearTimeout(this.searchTimer)

    this.searchTimer = window.setTimeout(() => {
      this.submitBookshelfSearch()
    }, 200)
  }

  private submitBookshelfSearch(): void {
    if (this.searchTimer) {
      clearTimeout(this.searchTimer)
      this.searchTimer = null
    }

    const form = this.element.closest("form")
    if (form instanceof HTMLFormElement) {
      form.requestSubmit()
    }
  }
}
