import "quagga"; // importmap にて UMD CDN を pin

document.addEventListener("DOMContentLoaded", () => {
  const scanner = document.getElementById("scanner");

  if (scanner && window.Quagga) {
    window.Quagga.init({
      inputStream: {
        name: "Live",
        type: "LiveStream",
        target: scanner,
        constraints: {
          facingMode: "environment",
          width: { min: 640 },
          height: { min: 240 },
        }
      },
      decoder: {
        readers: ["ean_reader"] // ← ここを強調
      },
      locate: false // ← 一旦 false に
    }, (err) => {
      if (err) {
        console.error("Quagga init error:", err);
        return;
      }
      window.Quagga.start();
    });

    window.Quagga.onDetected((data) => {
      const isbn = data.codeResult.code;
      console.log("ISBN Detected:", isbn);

      const input = document.getElementById("isbn_input");
      const button = document.getElementById("submit_button");

      if (input) input.value = isbn;
      if (button) button.disabled = false;

      // 読み取り後に停止する場合:
      // window.Quagga.stop();
    });
  }
});