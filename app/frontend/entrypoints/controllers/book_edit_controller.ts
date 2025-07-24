import { Controller } from "@hotwired/stimulus"

export default class BookEditController extends Controller<HTMLElement> {
  static targets = ["title", "author", "publisher"]
  static values = { id: Number, index: Number }

  declare readonly titleTarget: HTMLElement
  declare readonly authorTarget: HTMLElement
  declare readonly publisherTarget: HTMLElement
  declare readonly idValue: number
  declare readonly indexValue: number

  startEdit() {
    const title = this.titleTarget.textContent?.trim() ?? ""
    const author = this.authorTarget.textContent?.trim() ?? ""
    const publisher = this.publisherTarget.textContent?.trim() ?? ""

    this.titleTarget.innerHTML = `<input class="form-control form-control-sm" name="title" value="${title}" />`
    this.authorTarget.innerHTML = `<input class="form-control form-control-sm" name="author" value="${author}" />`
    this.publisherTarget.innerHTML = `<input class="form-control form-control-sm" name="publisher" value="${publisher}" />`

    const actionButtons = `
      <button class="btn btn-success btn-sm d-flex align-items-center" data-action="click->book-edit#save">✓</button>
      <button class="btn btn-secondary btn-sm d-flex align-items-center" data-action="click->book-edit#cancel">✕</button>
    `
    const lastCell = this.element.querySelector("td:last-child")
    if (lastCell) lastCell.innerHTML = actionButtons
  }

  cancel() {
    window.location.reload() // 安定性優先
  }

  save() {
    const id = this.idValue
    const index = this.indexValue
    const row = this.element

    const titleInput = row.querySelector<HTMLInputElement>("input[name='title']")
    const authorInput = row.querySelector<HTMLInputElement>("input[name='author']")
    const publisherInput = row.querySelector<HTMLInputElement>("input[name='publisher']")
    const csrfMeta = document.querySelector<HTMLMetaElement>("meta[name='csrf-token']")

    if (!titleInput || !authorInput || !publisherInput || !csrfMeta) {
      alert("入力値の取得に失敗しました。")
      return
    }

    const csrfToken = csrfMeta.getAttribute("content") ?? ""

    fetch(`/books/${id}/row`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({
        book: {
          title: titleInput.value,
          author: authorInput.value,
          publisher: publisherInput.value
        },
        index
      })
    })
      .then(response => {
        if (!response.ok) throw new Error("更新に失敗しました")
        return response.text()
      })
      .then(html => {
        this.element.insertAdjacentHTML("afterend", html)
        this.element.remove()
      })
      .catch(error => {
        alert(error.message)
      })
  }
}