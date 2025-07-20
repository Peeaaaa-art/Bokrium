import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { selectedTags: String }

  connect() {
    this.selectedSet = new Set((this.selectedTagsValue || "").split(",").filter(Boolean))
    this.updateUI()
  }

  toggle(event) {
    const name = event.target.dataset.tagToggleNameParam

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
    this.element.querySelectorAll(".tag-btn").forEach((btn) => {
      const name = btn.dataset.tagToggleNameParam
      btn.style.opacity = this.selectedSet.has(name) ? "1.0" : "0.5"
    })
  }
}