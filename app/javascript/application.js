// // Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
// import "@hotwired/turbo-rails"
// import "controllers"
// // 私が追加したもの
// import "@popperjs/core"
// import "bootstrap"
// import "@rails/activestorage"

import { Application } from "@hotwired/stimulus"
import AutogrowController from "./controllers/autogrow_controller"
import BarcodeController from "./controllers/barcode_controller"
import ScanController from "./controllers/scan_controller"
import SpinnerController from "./controllers/spinner_controller"
import ModalController from "./controllers/modal_controller"
import MemoModalController from "./controllers/memo_modal_controller"

const application = Application.start()
window.Stimulus = application

application.register("autogrow", AutogrowController)
application.register("barcode", BarcodeController)
application.register("scan", ScanController)
application.register("spinner", SpinnerController)
application.register("modal", ModalController)
application.register("memo-modal", MemoModalController)

import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap  // グローバルにしたい場合
import * as Turbo from "@hotwired/turbo"
window.Turbo = Turbo

// 他のファイルから使えるようにする場合（省略可）
export { application }

console.log("✅ Registered controllers:", application.controllers.map(c => c.identifier))