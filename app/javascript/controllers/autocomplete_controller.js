import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "suggestions"]
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

    clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout(() => {
      fetch(`${this.urlValue}?term=${encodeURIComponent(query)}`)
        .then((res) => res.json())
        .then((data) => {
          this.showSuggestions(data)
        })
        .catch((error) => console.error("Autocomplete error:", error))
    }, 200)
  }

  showSuggestions(suggestions) {
    this.clearSuggestions()

    suggestions.forEach((item) => {
      const li = document.createElement("li")
      li.className = "list-group-item p-0"

      const a = document.createElement("a")
      a.className = "d-block px-3 py-2 text-decoration-none text-body"
      a.innerHTML = item.label || item.value || "（無題）"
      a.href = item.url || "#"

    li.addEventListener("mousedown", (e) => {
      e.preventDefault()
      this.inputTarget.value = item.value
      this.clearSuggestions()
    })

      li.appendChild(a)
      this.suggestionsTarget.appendChild(li)
    })
  }

  clearSuggestions() {
    this.suggestionsTarget.innerHTML = ""
  }
}