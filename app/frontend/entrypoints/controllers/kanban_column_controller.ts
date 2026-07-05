import { Controller } from "@hotwired/stimulus"
import { renderStreamMessage } from "@hotwired/turbo"
import type Sortable from "sortablejs"
import { csrfToken } from "../utils/csrf"

// 読書戦略ボード(かんばん)の1列。列間ドラッグでステータス変更、
// 列内ドラッグで手動並び替え。どちらもドロップ後の列の並び(ordered_ids)を
// 丸ごとサーバーへ送り、status + board_position を確定させる。
// SortableJSはかんばんviewを開いたときだけ動的import する(既存バンドルに影響させない)
export default class KanbanColumnController extends Controller {
  static targets = ["list"]
  static values = { status: String, url: String }

  declare readonly listTarget: HTMLElement
  declare readonly statusValue: string
  declare readonly urlValue: string

  private sortable?: Sortable

  async connect() {
    const { default: SortableClass } = await import("sortablejs")
    this.sortable = SortableClass.create(this.listTarget, {
      group: "reading-kanban",
      animation: 150,
      delay: 150,
      delayOnTouchOnly: true, // iPadでスクロールとドラッグが競合しないようにする
      touchStartThreshold: 4,
      ghostClass: "kanban-ghost",
      // 列間移動はドロップ先の列(onAdd)、列内並び替えは同じ列(onUpdate)で発火する
      onAdd: (event) => {
        void this.persistColumn(event, { crossColumn: true })
      },
      onUpdate: (event) => {
        void this.persistColumn(event, { crossColumn: false })
      },
    })
  }

  disconnect() {
    this.sortable?.destroy()
    this.sortable = undefined
  }

  // この列の現在の並びを送信する。成功時はTurbo Streamで影響列が差し替わり、
  // ドロップ位置・並び順がそのまま確定する。失敗時はドラッグを巻き戻す
  private async persistColumn(
    event: Sortable.SortableEvent,
    { crossColumn }: { crossColumn: boolean }
  ) {
    const orderedIds = Array.from(
      this.listTarget.querySelectorAll<HTMLElement>("[data-book-id]")
    ).map((el) => el.dataset.bookId)

    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken(),
          Accept: "text/vnd.turbo-stream.html",
        },
        body: JSON.stringify({ status: this.statusValue, ordered_ids: orderedIds }),
      })
      if (!response.ok) {
        throw new Error(`column update failed: ${response.status}`)
      }
      renderStreamMessage(await response.text())
    } catch {
      if (crossColumn) {
        this.revertCrossColumn(event)
      } else {
        this.revertSameColumn(event)
      }
    }
  }

  private revertCrossColumn(event: Sortable.SortableEvent) {
    const reference = event.from.children[event.oldIndex ?? 0] ?? null
    event.from.insertBefore(event.item, reference)
  }

  private revertSameColumn(event: Sortable.SortableEvent) {
    const { item, from, oldIndex, newIndex } = event
    if (oldIndex == null || newIndex == null) return

    const offset = newIndex < oldIndex ? 1 : 0
    const reference = from.children[oldIndex + offset] ?? null
    from.insertBefore(item, reference)
  }
}
