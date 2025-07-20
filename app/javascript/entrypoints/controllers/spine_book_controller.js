import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "cover"]
  static values = { linkUrl: String }

  connect() {
    this.expanded = false
    this.handleDocumentClick = this.handleDocumentClick.bind(this)
    this.handleEscape = this.handleEscape.bind(this)
  }

  handleClick(event) {
    if (!this.expanded) {
      this.expand()
    } else {
      window.location.href = this.linkUrlValue
    }
  }

  expand() {
    this.expanded = true
    this.element.classList.add("expanded")

    if (this.hasCoverTarget) {
      this.element.classList.add("with-cover")
      this.coverTarget.classList.remove("d-none")
      this.titleTarget.classList.add("d-none")
    } else {
      this.titleTarget.classList.add("expanded-title")
    }

    document.addEventListener("click", this.handleDocumentClick)
    document.addEventListener("keydown", this.handleEscape)
  }

  collapse() {
    this.expanded = false
    this.element.classList.remove("expanded", "with-cover")
    this.element.classList.remove("expanded")

    if (this.hasCoverTarget) {
      this.coverTarget.classList.add("d-none")
      this.titleTarget.classList.remove("d-none")
    } else {
      this.titleTarget.classList.remove("expanded-title")
    }

    document.removeEventListener("click", this.handleDocumentClick)
    document.removeEventListener("keydown", this.handleEscape)
  }

  handleDocumentClick(event) {
    if (!this.element.contains(event.target)) {
      this.collapse()
    }
  }

  handleEscape(event) {
    if (event.key === "Escape") {
      this.collapse()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick)
    document.removeEventListener("keydown", this.handleEscape)
  }
}