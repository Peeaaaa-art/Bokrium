/*****************************************************
 * ▌█▀█▀█▀█ BARCODE RESULT CONTROLLER ▀█▀█▀█▀█▐
 * スキャンされたISBNをRailsに送信し、書誌情報を取得・表示
 *
 * 🔍 使用される書誌データソース（Rails側）:
 *   1. OpenBD
 *   2. 楽天ブックス（Rakuten Books API）
 *   3. Google Books API
 *   4. National Diet Library (NDL)
 *
 * 📡 フロント → fetch → Turbo Streamで結果を表示
 *****************************************************/
import { Controller } from "@hotwired/stimulus"
import { renderStreamMessage } from "@hotwired/turbo"
import { csrfToken } from "../utils/csrf"

interface ScanEvent extends CustomEvent {
  detail: {
    isbn: string
  }
}

export default class BarcodeResultController extends Controller {
  static values = {
    timeout: { type: Number, default: 2000 }
  }

  declare readonly timeoutValue: number

  scan(event: ScanEvent) {
    const isbn = event.detail.isbn
    if (!isbn || !isbn.startsWith("978")) return

    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), this.timeoutValue)

    fetch(`/search/isbn_turbo?isbn=${isbn}`, {
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-CSRF-Token": csrfToken(),
        "X-Requested-With": "XMLHttpRequest"
      },
      signal: controller.signal
    })
      .then((response) => {
        clearTimeout(timeoutId)

        if (!response.ok) {
          throw new Error(`${response.status} ${response.statusText}`)
        }

        return response.text().then((html) => {
          if (html.includes("<turbo-stream")) {
            renderStreamMessage(html)
            return html
          }
          throw new Error("Invalid Turbo Stream response")
        })
      })
      .catch((error: Error) => {
        renderStreamMessage(`
          <turbo-stream action="prepend" target="scanned-books">
            <template>
              通信エラー: ${error.message}
            </template>
          </turbo-stream>
        `)
      })
  }
}