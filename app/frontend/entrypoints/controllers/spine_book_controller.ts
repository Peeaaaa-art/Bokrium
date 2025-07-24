import { Controller } from "@hotwired/stimulus"

export default class BookSpineController extends Controller {
  static targets = ["title", "cover"]
  static values = {
    linkUrl: String
  }

  declare readonly titleTarget: HTMLElement
  declare readonly coverTarget: HTMLElement
  declare readonly hasCoverTarget: boolean
  declare readonly linkUrlValue: string

  private expanded = false
  private handleDocumentClick: (event: MouseEvent) => void = () => {}
  private handleEscape: (event: KeyboardEvent) => void = () => {}

  connect() {
    this.handleDocumentClick = this._handleDocumentClick.bind(this)
    this.handleEscape = this._handleEscape.bind(this)
  }

  handleClick(_event: Event) {
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

    if (this.hasCoverTarget) {
      this.coverTarget.classList.add("d-none")
      this.titleTarget.classList.remove("d-none")
    } else {
      this.titleTarget.classList.remove("expanded-title")
    }

    document.removeEventListener("click", this.handleDocumentClick)
    document.removeEventListener("keydown", this.handleEscape)
  }

  private _handleDocumentClick(event: MouseEvent) {
    if (!this.element.contains(event.target as Node)) {
      this.collapse()
    }
  }

  private _handleEscape(event: KeyboardEvent) {
    if (event.key === "Escape") {
      this.collapse()
    }
  }

  disconnect() {
    document.removeEventListener("click", this.handleDocumentClick)
    document.removeEventListener("keydown", this.handleEscape)
  }
}