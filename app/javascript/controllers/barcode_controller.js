import { Controller } from "@hotwired/stimulus"
import { BrowserMultiFormatReader } from "https://cdn.jsdelivr.net/npm/@zxing/browser/+esm";

export default class extends Controller {
  static targets = ["video", "output"]

  connect() {
    this.reader = new BrowserMultiFormatReader();
    this.startScanner();
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
}