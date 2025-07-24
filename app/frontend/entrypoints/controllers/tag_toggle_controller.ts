import { Controller } from "@hotwired/stimulus"

// タグの切り替えとTurboフレームへのリダイレクト制御
export default class TagToggleController extends Controller {
  static values = {
    selectedTags: String
  }

  declare selectedTagsValue: string
  private selectedSet: Set<string> = new Set()

  connect() {
    const tags = (this.selectedTagsValue || "")
      .split(",")
      .map(tag => tag.trim())
      .filter(tag => tag.length > 0)

    this.selectedSet = new Set(tags)
    this.updateUI()
  }

  toggle(event: Event) {
    const target = event.currentTarget as HTMLElement
    const name = target.dataset.tagToggleNameParam
    if (!name) return

    if (this.selectedSet.has(name)) {
      this.selectedSet.delete(name)
    } else {
      this.selectedSet.add(name)
    }

    this.updateUI()
    this.redirect()
  }

  redirect() {
    const url = new URL(window.location.href)
    url.searchParams.delete("tags")

    this.selectedSet.forEach(tag => {
      url.searchParams.append("tags", tag)
    })

    Turbo.visit(url.toString(), { frame: "books_frame" })
  }

  updateUI() {
    this.element.querySelectorAll<HTMLElement>(".tag-btn").forEach((btn) => {
      const name = btn.dataset.tagToggleNameParam
      if (!name) return

      btn.style.opacity = this.selectedSet.has(name) ? "1.0" : "0.5"
    })
  }
}