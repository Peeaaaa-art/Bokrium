import { Controller } from "@hotwired/stimulus"
import { renderStreamMessage } from "@hotwired/turbo"
import { csrfToken } from "../utils/csrf"

function isoDate(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, "0")
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

function addDays(base: Date, days: number): Date {
  const date = new Date(base)
  date.setDate(date.getDate() + days)
  return date
}

type DragMode = "move" | "start" | "end"

interface DragState {
  bar: HTMLElement
  mode: DragMode
  pointerId: number
  downX: number
  dayWidth: number
  startCol: number
  endCol: number
  currentStartCol: number
  currentEndCol: number
  originalGridColumn: string
}

// ロードマップのバーをドラッグして日付を変更する。
// 中央ドラッグ = 期間ごと平行移動、左右端ドラッグ = 開始日/目標日の個別変更。
// 1日単位スナップ。保存後はロードマップ全体がTurbo Streamで差し替わる
export default class RoadmapController extends Controller {
  static values = { totalDays: Number, windowStart: String }

  declare readonly totalDaysValue: number
  declare readonly windowStartValue: string

  // バーの端をつかんだと判定する幅(px)。バーが狭いときは全体を移動扱いにする
  private static readonly EDGE_PX = 10
  private static readonly MIN_RESIZE_WIDTH_PX = 28

  private drag?: DragState

  startDrag(event: PointerEvent) {
    if (event.button !== 0 && event.pointerType === "mouse") return

    const bar = event.currentTarget as HTMLElement
    const lane = bar.parentElement
    if (!lane) return

    event.preventDefault()

    const barRect = bar.getBoundingClientRect()
    const laneWidth = lane.getBoundingClientRect().width
    const offsetX = event.clientX - barRect.left

    let mode: DragMode = "move"
    if (barRect.width >= RoadmapController.MIN_RESIZE_WIDTH_PX) {
      if (offsetX < RoadmapController.EDGE_PX) mode = "start"
      else if (offsetX > barRect.width - RoadmapController.EDGE_PX) mode = "end"
    }

    const startCol = Number(bar.dataset.startCol)
    const endCol = Number(bar.dataset.endCol)

    this.drag = {
      bar,
      mode,
      pointerId: event.pointerId,
      downX: event.clientX,
      dayWidth: laneWidth / this.totalDaysValue,
      startCol,
      endCol,
      currentStartCol: startCol,
      currentEndCol: endCol,
      originalGridColumn: bar.style.gridColumn,
    }

    bar.setPointerCapture(event.pointerId)
    bar.addEventListener("pointermove", this.onPointerMove)
    bar.addEventListener("pointerup", this.onPointerUp)
    bar.addEventListener("pointercancel", this.onPointerCancel)
    document.body.style.cursor = mode === "move" ? "grabbing" : "col-resize"
  }

  disconnect() {
    this.teardown()
  }

  private onPointerMove = (event: PointerEvent) => {
    const drag = this.drag
    if (!drag) return

    event.preventDefault()
    const delta = Math.round((event.clientX - drag.downX) / drag.dayWidth)
    const total = this.totalDaysValue
    const length = drag.endCol - drag.startCol

    switch (drag.mode) {
      case "move": {
        const start = Math.min(Math.max(drag.startCol + delta, 1), total + 1 - length)
        drag.currentStartCol = start
        drag.currentEndCol = start + length
        break
      }
      case "start":
        drag.currentStartCol = Math.min(Math.max(drag.startCol + delta, 1), drag.endCol - 1)
        break
      case "end":
        drag.currentEndCol = Math.min(Math.max(drag.endCol + delta, drag.startCol + 1), total + 1)
        break
    }

    drag.bar.style.gridColumn = `${drag.currentStartCol} / ${drag.currentEndCol}`
  }

  private onPointerUp = () => {
    const drag = this.drag
    if (!drag) return

    const attributes = this.buildAttributes(drag)
    this.teardown()

    if (attributes) {
      void this.persist(drag, attributes)
    }
  }

  private onPointerCancel = () => {
    if (this.drag) {
      this.drag.bar.style.gridColumn = this.drag.originalGridColumn
    }
    this.teardown()
  }

  // ドラッグ結果を日付に変換する。動きがなければ null。
  // 平行移動は実際の日付に差分を足す(ウィンドウ外に切り詰めたバーでも正しくずれる)。
  // 端のリサイズは置いた位置の日付をそのまま採用する
  private buildAttributes(drag: DragState): Record<string, string> | null {
    const deltaStart = drag.currentStartCol - drag.startCol
    const deltaEnd = drag.currentEndCol - drag.endCol
    if (deltaStart === 0 && deltaEnd === 0) return null

    const windowStart = new Date(`${this.windowStartValue}T00:00:00`)
    const dateAtCol = (col: number) => addDays(windowStart, col - 1)
    const startedOn = drag.bar.dataset.startedOn
    const targetOn = drag.bar.dataset.targetOn
    if (!targetOn) return null

    const startedBase = startedOn
      ? new Date(`${startedOn}T00:00:00`)
      : dateAtCol(drag.startCol)
    const targetBase = new Date(`${targetOn}T00:00:00`)

    switch (drag.mode) {
      case "move":
        return {
          started_on: isoDate(addDays(startedBase, deltaStart)),
          target_finish_on: isoDate(addDays(targetBase, deltaStart)),
        }
      case "start":
        return { started_on: isoDate(dateAtCol(drag.currentStartCol)) }
      case "end":
        return { target_finish_on: isoDate(dateAtCol(drag.currentEndCol - 1)) }
    }
  }

  private async persist(drag: DragState, attributes: Record<string, string>) {
    const url = drag.bar.dataset.roadmapUrl
    if (!url) return

    try {
      const response = await fetch(url, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken(),
          Accept: "text/vnd.turbo-stream.html",
        },
        body: JSON.stringify({ book: attributes, view_context: "roadmap" }),
      })
      if (!response.ok) {
        throw new Error(`roadmap update failed: ${response.status}`)
      }
      renderStreamMessage(await response.text())
    } catch {
      drag.bar.style.gridColumn = drag.originalGridColumn
    }
  }

  private teardown() {
    const drag = this.drag
    if (drag) {
      drag.bar.removeEventListener("pointermove", this.onPointerMove)
      drag.bar.removeEventListener("pointerup", this.onPointerUp)
      drag.bar.removeEventListener("pointercancel", this.onPointerCancel)
      if (drag.bar.hasPointerCapture(drag.pointerId)) {
        drag.bar.releasePointerCapture(drag.pointerId)
      }
    }
    document.body.style.cursor = ""
    this.drag = undefined
  }
}
