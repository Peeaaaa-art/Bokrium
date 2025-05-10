// app/javascript/controllers/book_shelf_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const slice = this.getSliceCount()

    const currentUrl = new URL(window.location.href)
    const currentSlice = currentUrl.searchParams.get("slice")

    if (parseInt(currentSlice) !== slice) {
      currentUrl.searchParams.set("slice", slice)
      window.location.href = currentUrl.toString()
    }
  }

  getSliceCount() {
    const width = window.innerWidth

    // if (width < 768) return 4
    // if (width < 1200) return 8
    if (width < 1700) return 8
    if (width < 1900) return 10
    if (width < 2000) return 11
    return 12
  }
}