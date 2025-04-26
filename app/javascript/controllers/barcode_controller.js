import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader } from "https://cdn.jsdelivr.net/npm/@zxing/browser/+esm";

export default class extends Controller {
  static targets = ["video", "output"]
  static values = { debounce: { type: Number, default: 1000 } }

  connect() {
    this.scannedIsbns = new Set();
    this.isProcessing = false;
    this.reader = new BrowserMultiFormatReader();
    this.reader.options = {
      possibleFormats: ['EAN_13'],
      tryHarder: true
    };
    this.startScanner();
    this.createScanFrame()
  }

  async startScanner() {
    try {
      await this.reader.decodeFromConstraints({
        video: {
          facingMode: { ideal: "environment" }
        }
      }, this.videoTarget, async (result, err) => {
        if (result && !this.isProcessing) {
          const isbn = result.getText();
          if (isbn.startsWith('978') && !this.scannedIsbns.has(isbn)) {
            this.isProcessing = true;
            this.scannedIsbns.add(isbn);

            try {
              this.dispatch("scan", {
                detail: { isbn },
                bubbles: true, // 必須
                cancelable: true,
                prefix: "barcode",
                target: window // 明示的にwindowをターゲットに指定
              });

            console.log('DISPATCHED scan event with ISBN:', isbn);

            this.outputTarget.textContent = `検出: ${isbn}`;
            
            await new Promise(resolve => setTimeout(resolve, this.debounceValue));
          } finally {
            this.isProcessing = false;
          }
        }
      }
    });
    } catch (e) {
      this.outputTarget.textContent = `エラー: ${e.message}`;
    }
  }
  
  disconnect() {
    if (this.reader) {
      this.reader.reset();
    }
  }

  createScanFrame() {
    const frame = document.createElement('div')
    frame.classList.add('dynamic-scan-frame')
    frame.style.position = 'absolute'
    frame.style.top = '35%'
    frame.style.left = '25%'
    frame.style.width = '50%'
    frame.style.height = '30%'
    frame.style.border = '4px solid rgba(227, 221, 216, 0.66)'
    frame.style.borderRadius = '8px';
    frame.style.boxSizing = 'border-box'
    frame.style.pointerEvents = 'none'
    frame.style.zIndex = '1000'

    const wrapper = this.videoTarget.parentElement
    wrapper.appendChild(frame)
  }
}
