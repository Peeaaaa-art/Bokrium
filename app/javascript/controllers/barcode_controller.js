import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader } from "https://cdn.jsdelivr.net/npm/@zxing/browser/+esm";

export default class extends Controller {
  static targets = ["video", "output"]

  connect() {
    this.reader = new BrowserMultiFormatReader();
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
          this.outputTarget.textContent = `ISBN: ${result.getText()}`;
          this.reader.reset();
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
    frame.style.border = '4px solid rgb(181, 31, 31)'
    frame.style.boxSizing = 'border-box'
    frame.style.pointerEvents = 'none'
    frame.style.zIndex = '1000'
    
    // ビデオラッパーに枠を追加
    const wrapper = this.videoTarget.parentElement
    wrapper.appendChild(frame)
  }
}