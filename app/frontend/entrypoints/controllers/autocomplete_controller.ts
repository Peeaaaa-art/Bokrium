import { Controller } from "@hotwired/stimulus"

interface SuggestionItem {
  label?: string
  value?: string
  url?: string
}

export default class AutocompleteController extends Controller {
  static targets = ["input", "suggestions"]
  static values = {
    url: String
  }

  declare readonly inputTarget: HTMLInputElement
  declare readonly suggestionsTarget: HTMLElement
  declare readonly urlValue: string

  private debounceTimer: number | null = null

  connect(): void {
    this.debounceTimer = null
  }

  fetchSuggestions(event: Event): void {
    const target = event.target as HTMLInputElement
    const query = target.value.trim()

    if (query.length < 1) {
      this.clearSuggestions()
      return
    }

    if (this.debounceTimer) clearTimeout(this.debounceTimer)

    this.debounceTimer = window.setTimeout(() => {
      const url = `${this.urlValue}&term=${encodeURIComponent(query)}&_ts=${Date.now()}`

      fetch(url)
        .then((res) => res.json())
        .then((data: SuggestionItem[]) => {
          this.showSuggestions(data)
        })
        .catch((error) => console.error("Autocomplete error:", error))
    }, 200)
  }

  showSuggestions(suggestions: SuggestionItem[]): void {
    this.clearSuggestions()

    suggestions.forEach((item) => {
      const li = document.createElement("li")
      li.className = "list-group-item p-0"

      const a = document.createElement("a")
      a.className = "d-block px-3 py-2 text-decoration-none text-black-50"
      a.innerHTML = item.label || item.value || "（無題）"
      a.href = item.url || "#"

      li.addEventListener("mousedown", (e) => {
        e.preventDefault()
        this.inputTarget.value = item.value || ""
        this.clearSuggestions()
      })

      li.appendChild(a)
      this.suggestionsTarget.appendChild(li)
    })
  }

  clearSuggestions(): void {
    this.suggestionsTarget.innerHTML = ""
  }
}