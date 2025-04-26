import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader } from "https://cdn.jsdelivr.net/npm/@zxing/browser/+esm";

export default class extends Controller {
  static targets = ["video", "output"]

  connect() {
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
      }, this.videoTarget, (result, err) => {
        if (result) {
          const isbn = result.getText();
          if (isbn.startsWith('978')) {
            this.outputTarget.textContent = `ISBN: ${isbn}`;
            this.reader.reset();
          } else {
            console.log('無効なバーコード', isbn);
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