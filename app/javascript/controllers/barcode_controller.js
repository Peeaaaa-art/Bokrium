import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader } from "https://cdn.jsdelivr.net/npm/@zxing/browser/+esm";

export default class extends Controller {
  static targets = ["video", "output"]

  connect() {
    this.reader = new BrowserMultiFormatReader();
    // フォーマット制限を追加
    this.reader.options = {
      possibleFormats: ['EAN_13'],
      tryHarder: true
    };
    this.startScanner();
    // 赤枠の動的生成
    this.createScanFrame()
  }

  async startScanner() {
    try {
      const devices = await navigator.mediaDevices.enumerateDevices();
      const videoDevices = devices.filter(device => device.kind === "videoinput");

      if (videoDevices.length === 0) {
        this.outputTarget.textContent = "カメラが見つかりません";
        return;
      }

      const selectedDeviceId = videoDevices[0].deviceId;

      this.reader.decodeFromVideoDevice(selectedDeviceId, this.videoTarget, (result, err) => {
        if (result) {
          const isbn = result.getText();
          // 978から始まるバーコードのみ処理
          if (isbn.startsWith('978')) {
            this.outputTarget.textContent = `ISBN: ${result.getText()}`;
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
    // 既存の枠を削除
    const existingFrame = this.element.querySelector('.dynamic-scan-frame')
    if (existingFrame) existingFrame.remove()
    
    // 新しい枠を作成
    const frame = document.createElement('div')
    frame.classList.add('dynamic-scan-frame')
    frame.style.position = 'absolute'
    frame.style.top = '35%'
    frame.style.left = '25%'
    frame.style.width = '50%'
    frame.style.height = '30%'
    frame.style.border = '4px solid rgba(227, 221, 216, 0.66)'
    frame.style.boxSizing = 'border-box'
    frame.style.pointerEvents = 'none'
    frame.style.zIndex = '1000'
    
    // ビデオラッパーに枠を追加
    const wrapper = this.videoTarget.parentElement
    wrapper.appendChild(frame)
  }
}