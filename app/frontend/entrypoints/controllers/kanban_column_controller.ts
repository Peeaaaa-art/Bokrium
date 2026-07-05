import { Controller } from "@hotwired/stimulus"
import { renderStreamMessage } from "@hotwired/turbo"
import type Sortable from "sortablejs"

function csrfToken(): string {
  return (
    document.querySelector<HTMLMetaElement>("meta[name='csrf-token']")?.content ?? ""
  )
}

// 読書戦略ボード(かんばん)の1列。カードを別の列へドラッグするとステータスを変更する。
// SortableJSはかんばんviewを開いたときだけ動的import する(既存ページのバンドルに影響させない)
export default class KanbanColumnController extends Controller {
  static targets = ["list"]
  static values = { status: String }

  declare readonly listTarget: HTMLElement
  declare readonly statusValue: string

  private sortable?: Sortable

  async connect() {
    const { default: SortableClass } = await import("sortablejs")
    this.sortable = SortableClass.create(this.listTarget, {
      group: "reading-kanban",
      sort: false, // 列内の手動並び替えはしない(順序はサーバーが決める)
      animation: 150,
      delay: 150,
      delayOnTouchOnly: true, // iPadでスクロールとドラッグが競合しないようにする
      touchStartThreshold: 4,
      ghostClass: "kanban-ghost",
      onAdd: (event) => {
        void this.updateStatus(event)
      },
    })
  }

  disconnect() {
    this.sortable?.destroy()
    this.sortable = undefined
  }

  // 他の列からカードを受け取ったら、その本のステータスをこの列の値に更新する。
  // 成功時はTurbo Streamで移動元・先の両列が差し替わる(サーバーの順序が正)。
  // 失敗時はカードを元の列へ戻す
  private async updateStatus(event: Sortable.SortableEvent) {
    const url = (event.item as HTMLElement).dataset.statusUrl
    if (!url) return

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken(),
          Accept: "text/vnd.turbo-stream.html",
        },
        body: JSON.stringify({ book: { status: this.statusValue } }),
      })
      if (!response.ok) {
        throw new Error(`status update failed: ${response.status}`)
      }
      renderStreamMessage(await response.text())
    } catch {
      this.revert(event)
    }
  }

  private revert(event: Sortable.SortableEvent) {
    const reference = event.from.children[event.oldIndex ?? 0] ?? null
    event.from.insertBefore(event.item, reference)
  }
}
