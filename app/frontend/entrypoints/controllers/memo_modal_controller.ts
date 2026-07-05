import { Controller } from "@hotwired/stimulus"
import { prepareMemoHtmlForSave } from "../utils/memo_links"
import { normalizeProseMirrorHtmlForSave } from "../utils/prosemirror_html"



export default class MemoModalController extends Controller<HTMLElement> {
  static values = {
    initialContent: String,
    memoId: String,
    bookId: String,
    createdAt: String,
    updatedAt: String
  }

  static targets = ["body", "icon"]

  declare readonly hasBodyTarget: boolean
  declare readonly hasIconTarget: boolean
  declare readonly bodyTarget: HTMLElement
  declare readonly iconTarget: HTMLElement

  submitHandler!: EventListener
  expanded: boolean = false
  private touchStartPoint: { x: number; y: number; time: number } | null = null

  connect() {
    this.submitHandler = this.handleSubmit.bind(this)
  }

  trackTouchStart(event: TouchEvent) {
    const touch = event.touches[0]
    if (!touch) return

    this.touchStartPoint = {
      x: touch.clientX,
      y: touch.clientY,
      time: Date.now()
    }
  }

  async open(event: Event) {
    if (this.shouldIgnoreOpen(event)) return

    if (event.type === "touchend") {
      if (!this.isTapGesture(event as TouchEvent)) return
      event.preventDefault()
    }

    (document.activeElement as HTMLElement | null)?.blur?.() // iOS Safari 対策

    const trigger = event.currentTarget as HTMLElement

    const memoId = trigger.dataset.memoModalMemoIdValue!
    const bookId = trigger.dataset.memoModalBookIdValue!
    const createdAtFull = trigger.dataset.memoModalCreatedAtValue
    const updatedAtFull = trigger.dataset.memoModalUpdatedAtValue
    const createdAtShort = trigger.dataset.memoModalCreatedDateValue
    const updatedAtShort = trigger.dataset.memoModalUpdatedDateValue

    const contentElement = this.element.querySelector(".tiptap-body")
    const contentHTML = contentElement?.innerHTML || ""
    const isPlaceholder = contentHTML.includes("PLACEHOLDER_TOKEN_9fz3!ifhdas094hfgfygq@_$2x")
    const initialContent = isPlaceholder ? "" : contentHTML

    const editorRoot = document.getElementById("rich-editor-root")
    if (editorRoot) {
      window.hasUnsavedChanges = false
      editorRoot.dataset.initialContent = initialContent
      editorRoot.dataset.memoId = memoId

      // TipTap+Reactは重いためモーダルを開くときに初めて読み込む
      const { mountRichEditor } = await import("../rich_editor")
      mountRichEditor(editorRoot)

      const observer = new MutationObserver(() => {
        const proseMirror = editorRoot.querySelector(".ProseMirror")
        if (proseMirror) {
          proseMirror.classList.add("editing")
          observer.disconnect()
        }
      })

      observer.observe(editorRoot, { childList: true, subtree: true })
    }

    const hiddenField = document.getElementById("memo_content_input") as HTMLInputElement | null
    if (hiddenField) hiddenField.value = initialContent

    const form = document.getElementById("memo-edit-form") as HTMLFormElement | null
    if (form) {
      form.setAttribute("action", memoId === "new" ? `/books/${bookId}/memos` : `/books/${bookId}/memos/${memoId}`)
      form.setAttribute("method", "post")

      let methodInput = form.querySelector("input[name='_method']") as HTMLInputElement | null
      if (memoId !== "new") {
        if (!methodInput) {
          methodInput = document.createElement("input")
          methodInput.type = "hidden"
          methodInput.name = "_method"
          form.appendChild(methodInput)
        }
        methodInput.value = "patch"
      } else {
        methodInput?.remove()
      }

      form.removeEventListener("submit", this.submitHandler)
      form.addEventListener("submit", this.submitHandler)
      form.scrollIntoView({ behavior: "smooth", block: "center" })
    }

    const createdAtEl = document.getElementById("modal-created-at")
    const updatedAtEl = document.getElementById("modal-updated-at")
    const isMobile = window.innerWidth < 576

    const fallbackDate = (full: string | undefined) => full?.split(" ")[0] || ""

    if (createdAtEl) {
      createdAtEl.textContent = createdAtFull
        ? `作成日: ${isMobile ? createdAtShort || fallbackDate(createdAtFull) : createdAtFull}`
        : ""
    }

    if (updatedAtEl) {
      updatedAtEl.textContent = updatedAtFull
        ? `更新日: ${isMobile ? updatedAtShort || fallbackDate(updatedAtFull) : updatedAtFull}`
        : ""
    }

    const modalElement = document.getElementById("memoEditModal")
    if (!modalElement) {
      console.error("❌ モーダルが見つかりません: memoEditModal")
      return
    }

    const modal = new (window as any).bootstrap.Modal(modalElement)
    modal.show()
  }

  private shouldIgnoreOpen(event: Event): boolean {
    const trigger = event.currentTarget as HTMLElement | null
    const target = event.target as HTMLElement | null
    if (!trigger || !target || target === trigger) return false

    return Boolean(
      target.closest("a, button, input, select, textarea, label, summary, [role='button'], [data-bs-toggle], form")
    )
  }

  private isTapGesture(event: TouchEvent): boolean {
    const start = this.touchStartPoint
    const touch = event.changedTouches[0]
    this.touchStartPoint = null

    if (!start || !touch) return false

    const movementX = Math.abs(touch.clientX - start.x)
    const movementY = Math.abs(touch.clientY - start.y)
    const elapsed = Date.now() - start.time

    return movementX <= 12 && movementY <= 12 && elapsed <= 700
  }

  toggle(event: Event) {
    event.stopPropagation()
    this.expanded = !this.expanded
    this.bodyTarget.classList.toggle("expanded", this.expanded)

    this.iconTarget.classList.toggle("bi-arrows-angle-expand", !this.expanded)
    this.iconTarget.classList.toggle("bi-arrows-angle-contract", this.expanded)
  }

  handleSubmit() {
    const editorRoot = document.getElementById("rich-editor-root")
    const rawContent = editorRoot?.querySelector(".ProseMirror")?.innerHTML || ""
    const updatedContent = prepareMemoHtmlForSave(normalizeProseMirrorHtmlForSave(rawContent))
    const hiddenField = document.getElementById("memo_content_input") as HTMLInputElement | null
    if (hiddenField) hiddenField.value = updatedContent

    console.log("📜 フォーム送信直前: content =", updatedContent)
  }

  stop(event: Event) {
    event.stopPropagation()
  }

  disconnect() {
    const editorRoot = document.getElementById("rich-editor-root")
    const proseMirror = editorRoot?.querySelector(".ProseMirror")
    if (proseMirror) {
      proseMirror.classList.remove("editing")
    }
  }
}
