import "quagga";

document.addEventListener("DOMContentLoaded", () => {
  const scanner = document.getElementById("scanner");

  if (scanner) {
    Quagga.init({
      inputStream: {
        type: "LiveStream",
        target: scanner,
        constraints: {
          facingMode: "environment" // 背面カメラ指定
        }
      },
      decoder: {
        readers: ["ean_reader"] // ISBNコード用バーコード
      }
    }, (err) => {
      if (err) {
        console.error(err);
        return;
      }
      Quagga.start();
    });

    Quagga.onDetected((data) => {
      const isbn = data.codeResult.code;
      console.log("ISBN Detected:", isbn);

      // ここでinput要素に挿入もできる
      const input = document.getElementById("isbn_input");
      if (input) {
        input.value = isbn;
      }
    });
  }
});