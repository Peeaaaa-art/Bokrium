import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader } from "@zxing/browser"

let scannerStarted = false

export default class extends Controller {
  static targets = ["video", "output"]
  static values = { debounce: { type: Number, default: 1500 } }

  connect() {
    console.log("📸 barcode_controller connected!")

    if (scannerStarted) {
      console.warn("⚠️ スキャナーはすでに起動済みです")
      return
    }

    scannerStarted = true
    this.scannedIsbns = new Set()
    this.reader = new BrowserMultiFormatReader()
    this.reader.options = {
      possibleFormats: ["EAN_13"],
      tryHarder: true,
    }

    // 👇 Turboによる画面遷移時にカメラを強制停止
    this.cleanupHandler = this.stopCamera.bind(this)
    document.addEventListener("turbo:before-render", this.cleanupHandler)

    this.startScanner()
    this.createScanFrame()
  }

  startScanner() {
    this.reader.decodeFromVideoDevice(null, this.videoTarget, async (result, err, controls) => {
      if (!result) return

      const isbn = result.getText()

      if (!isbn.startsWith("978") || this.scannedIsbns.has(isbn)) return

      console.log("📘 ISBN detected:", isbn)
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
        controls.resume?.()
      }, this.debounceValue)
    })
  }

  disconnect() {
    this.stopCamera()
    document.removeEventListener("turbo:before-render", this.cleanupHandler)
  }

  stopCamera() {
    if (this.reader?.reset) this.reader.reset()

    const stream = this.videoTarget?.srcObject
    if (stream) {
      stream.getTracks().forEach((track) => track.stop())
      this.videoTarget.srcObject = null
      console.log("📴 カメラストリームを停止しました")
    }

    scannerStarted = false
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
    this.videoTarget.parentElement.appendChild(frame)
  }
}