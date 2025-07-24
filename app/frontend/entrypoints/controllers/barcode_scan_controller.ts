/*********************************************
 * ▌█▀█▀█▀█ BARCODE SCAN CONTROLLER ▀█▀█▀█▀█▐
 * ISBN（EAN-13）をカメラからリアルタイム読み取り
 * 使用技術: Stimulus + ZXing + Turbo Stream
 *********************************************/
import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader, BarcodeFormat } from "@zxing/browser"

export default class BarcodeScanController extends Controller {
  private static scannerStarted = false

  static targets = ["video", "output"]
  static values = {
    debounce: Number  // 読み取り後の再読み取りまでの待機時間（ms）
  }

  declare readonly videoTarget: HTMLVideoElement
  declare readonly outputTarget: HTMLElement
  declare readonly debounceValue: number

  private scannedIsbns = new Set<string>()
  private reader: BrowserMultiFormatReader | null = null
  private cleanupHandler!: () => void

  private handleVisibility = () => {
    if (document.visibilityState === "hidden") this.stopCamera()
  }

  connect() {
    if (BarcodeScanController.scannerStarted) return

    BarcodeScanController.scannerStarted = true
    this.scannedIsbns.clear()

    this.reader = new BrowserMultiFormatReader()

    this.reader.hints.set(
      0x3, // ZXing内部でDecodeHintType.POSSIBLE_FORMATSに相当
      [BarcodeFormat.EAN_13]
    )

    this.cleanupHandler = this.stopCamera.bind(this)
    document.addEventListener("turbo:before-visit", this.cleanupHandler)
    document.addEventListener("turbo:before-cache", this.cleanupHandler)
    document.addEventListener("visibilitychange", this.handleVisibility)

    this.startScanner()
    this.createScanFrame()
  }

  disconnect() {
    this.stopCamera()

    document.removeEventListener("turbo:before-visit", this.cleanupHandler)
    document.removeEventListener("turbo:before-cache", this.cleanupHandler)
    document.removeEventListener("visibilitychange", this.handleVisibility)
  }

  startScanner() {
    if (!this.reader) return

    this.reader.decodeFromVideoDevice(
      undefined,
      this.videoTarget,
      (result, err, controls: any) => {
        if (!result) return

        const isbn = result.getText()
        if (!isbn.startsWith("978") || this.scannedIsbns.has(isbn)) return

        this.scannedIsbns.add(isbn)

        this.dispatch("scan", {
          detail: { isbn },
          bubbles: true,
          cancelable: true,
          prefix: "barcode",
          target: window,
        })

        this.outputTarget.textContent = `ISBN: ${isbn}`

        setTimeout(() => {
          controls?.resume?.()
        }, this.debounceValue)
      }
    )
  }

  async stopCamera() {
    try {
      const video = this.videoTarget

      if (this.reader) {
        await (this.reader as any).stopDecoding?.()
        ;(this.reader as any).reset?.()
        this.reader = null
      }

      const stream = video?.srcObject as MediaStream | null
      if (stream) {
        stream.getTracks().forEach((track) => {
          if (track.readyState === "live") {
            track.stop()
          }
        })
      }

      if (video) {
        video.pause()
        video.srcObject = null
        video.removeAttribute("src")
        video.load()
      }
    } catch (e) {
      console.warn("stopCamera error:", e)
    }

    BarcodeScanController.scannerStarted = false
  }

  createScanFrame() {
    const frame = document.createElement("div")
    Object.assign(frame.style, {
      position: "absolute",
      top: "30%",
      left: "28%",
      width: "45%",
      height: "40%",
      border: "4px solid rgba(227, 221, 216, 0.66)",
      borderRadius: "8px",
      boxSizing: "border-box",
      pointerEvents: "none",
      zIndex: "1000",
    })
    this.videoTarget.parentElement?.appendChild(frame)
  }
}