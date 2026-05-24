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

  private suggestionsTimer: number | null = null
  private searchTimer: number | null = null

  connect(): void {
    this.suggestionsTimer = null
    this.searchTimer = null
  }

  disconnect(): void {
    if (this.suggestionsTimer) clearTimeout(this.suggestionsTimer)
    if (this.searchTimer) clearTimeout(this.searchTimer)
  }

  fetchSuggestions(event: Event): void {
    const target = event.target as HTMLInputElement
    const query = target.value.trim()

    if (query.length < 1) {
      this.clearSuggestions()
      this.scheduleBookshelfSearch()
      return
    }

    this.scheduleBookshelfSearch()

    if (this.suggestionsTimer) clearTimeout(this.suggestionsTimer)

    this.suggestionsTimer = window.setTimeout(() => {
      const url = `${this.urlValue}&term=${encodeURIComponent(query)}&_ts=${Date.now()}`

      fetch(url)
        .then((res) => res.json())
        .then((data: SuggestionItem[]) => {
          if (this.inputTarget.value.trim() !== query) return

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
      a.textContent = item.label || item.value || "（無題）"
      a.href = item.url || "#"

      li.addEventListener("mousedown", (e) => {
        e.preventDefault()
        this.inputTarget.value = item.value || ""
        this.clearSuggestions()
        this.submitBookshelfSearch()
      })

      a.addEventListener("click", (e) => {
        e.preventDefault()
      })

      li.appendChild(a)
      this.suggestionsTarget.appendChild(li)
    })
  }

  clearSuggestions(): void {
    this.suggestionsTarget.innerHTML = ""
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
