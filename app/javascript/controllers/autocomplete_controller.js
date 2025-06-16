import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]
  static values = { url: String }

  connect() {
    this.debounceTimer = null
  }

  fetchSuggestions(event) {
    const query = event.target.value.trim()
    if (query.length < 1) {
      this.clearSuggestions()
      return
    }

    console.log("⏳ fetchSuggestions", query)

    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      fetch(`${this.urlValue}?term=${encodeURIComponent(query)}`)
        .then((res) => res.json())
        .then((data) => {
          console.log("🎯 suggestions:", data)
          this.showSuggestions(data)
        })
        .catch((error) => console.error("Autocomplete error:", error))
    }, 200)
  }

  showSuggestions(suggestions) {
    this.clearSuggestions()

    const container = document.createElement("ul")
    container.classList.add(
      "autocomplete-suggestions-container",
      "list-group",
      "position-absolute",
      "w-100",
      "z-3"
    )
    container.style.top = "100%"
    container.style.left = "0"

    suggestions.forEach((item, i) => {
      console.log(`🧩 li item[${i}]:`, item)
      const li = document.createElement("li")
      li.className = "list-group-item list-group-item-action"
      li.innerHTML = item.label || item.value || "（無題）"

      li.addEventListener("click", () => {
        this.inputTarget.value = item.value
        this.clearSuggestions()
      })

      container.appendChild(li)
    })

    this.inputTarget.parentNode.appendChild(container)
  }

  clearSuggestions() {
    const existing = this.inputTarget.parentNode.querySelector(".autocomplete-suggestions-container")
    if (existing) existing.remove()
  }
}