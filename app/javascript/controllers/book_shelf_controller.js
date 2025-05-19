import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const width = window.innerWidth
    let booksPerRow = 12

    if (width < 576) {
      booksPerRow = 5
    } else if (width < 768) {
      booksPerRow = 7
    } else if (width < 992) {
      booksPerRow = 9
    } else if (width < 1200) {
      booksPerRow = 11
    }

    const currentParams = new URLSearchParams(window.location.search)
    const currentSlice = parseInt(currentParams.get("slice"))

    if (!currentSlice || currentSlice !== booksPerRow) {
      currentParams.set("slice", booksPerRow)
      const newUrl = `${window.location.pathname}?${currentParams.toString()}`
      Turbo.visit(newUrl, { action: "replace" })
    }
  }
}