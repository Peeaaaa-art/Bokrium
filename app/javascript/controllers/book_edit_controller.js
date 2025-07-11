import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "author", "publisher"]
  static values = { id: Number, index: Number }

  startEdit() {
    this.titleTarget.innerHTML = `<input class="form-control form-control-sm" name="title" value="${this.titleTarget.textContent.trim()}" />`
    this.authorTarget.innerHTML = `<input class="form-control form-control-sm" name="author" value="${this.authorTarget.textContent.trim()}" />`
    this.publisherTarget.innerHTML = `<input class="form-control form-control-sm" name="publisher" value="${this.publisherTarget.textContent.trim()}" />`

    this.element.querySelector("td:last-child").innerHTML = `
      <button class="btn btn-success btn-sm d-flex align-items-center" data-action="click->book-edit#save">
        <i class="bi bi-check-lg"></i>
      </button>
      <button class="btn btn-secondary btn-sm d-flex align-items-center" data-action="click->book-edit#cancel">
        <i class="bi bi-x-lg"></i>
      </button>
    `
  }

  cancel() {
    window.location.reload()// 安定性優先：本棚全体をリロード
  }

  save() {
    const id = this.idValue
    const index = this.indexValue
    const row = this.element
    const title = row.querySelector("input[name='title']").value
    const author = row.querySelector("input[name='author']").value
    const publisher = row.querySelector("input[name='publisher']").value
    const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

    fetch(`/books/${id}/row`, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken
      },
      body: JSON.stringify({
        book: { title, author, publisher },
        index: index
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