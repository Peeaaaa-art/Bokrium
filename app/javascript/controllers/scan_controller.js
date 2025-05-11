import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { timeout: { type: Number, default: 5000 } }

  scan(event) {
    console.log("📥 ScanController received:", event.detail.isbn)
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
      console.log("Response status:", response.status);
      clearTimeout(timeoutId);

      if (!response.ok) {
        throw new Error(`${response.status} ${response.statusText}`);
      }

      return response.text().then(html => {
        console.log("Raw Response:", html);

        if (typeof html === "string" && html.includes("<turbo-stream")) {
          Turbo.renderStreamMessage(html);
          return html;
        }
        throw new Error("Invalid Turbo Stream response");
      });
    })
    .catch(error => {
      console.error("検索エラー:", error);
      Turbo.renderStreamMessage(
        `<turbo-stream action="prepend" target="scanned-books">
          <template>
            <div class="alert alert-danger">通信エラー: ${error.message}</div>
          </template>
        </turbo-stream>`
      );
    });
  }

  getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]').content;
  }
}