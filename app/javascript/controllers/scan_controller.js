import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 5000 } }

  scan(event) {
    const isbn = event.detail.isbn;
    if (!isbn || !isbn.startsWith('978')) return;

    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutValue);

    fetch(`/search/isbn_turbo?isbn=${isbn}`, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": this.getCsrfToken(),
        "X-Requested-With": "XMLHttpRequest"
      },
      signal: controller.signal
    })
    .then(response => {
      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`${response.status} ${response.statusText}`);
      }

      return response.text().then(html => {
        if (typeof html === "string" && html.includes("<turbo-stream")) {
          Turbo.renderStreamMessage(html);
          return html;
        }
        throw new Error("Invalid Turbo Stream response");
      });
    })
    .catch(error => {
      Turbo.renderStreamMessage(
        `<turbo-stream action="prepend" target="scanned-books">
          <template>
            通信エラー: ${error.message}
          </template>
        </turbo-stream>`
      );
    });
  }

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content;
  }
}