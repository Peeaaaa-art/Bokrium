import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  scan(event) {
    const isbn = event.detail.isbn;
    if (!isbn || !isbn.startsWith('978')) return;
    
    console.log(`ISBN: ${isbn} で検索を実行します`);
    
    fetch(`/books/search_isbn_turbo?isbn=${isbn}`, {
      headers: { 
        Accept: "text/vnd.turbo-stream.html, text/html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(response => {
      const contentType = response.headers.get("Content-Type");
      if (contentType && contentType.includes("turbo-stream")) {
        return response.text().then(html => {
          Turbo.renderStreamMessage(html);
        });
      } else {
        return response.text().then(html => {
          const frame = document.querySelector("#scanned-books");
          frame.innerHTML = html;
        });
      }
    })
    .catch(error => {
      console.error("検索エラー:", error);
    });
  }
}
