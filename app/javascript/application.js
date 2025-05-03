import { Application } from "@hotwired/stimulus"
import BarcodeController from "./controllers/barcode_controller"
import ScanController from "./controllers/scan_controller"
import SpinnerController from "./controllers/spinner_controller"
import ImageModalController from "./controllers/image_modal_controller"
import MemoModalController from "./controllers/memo_modal_controller"
import ImageUploadController from "./controllers/image_upload_controller"

const application = Application.start()
window.Stimulus = application

application.register("barcode", BarcodeController)
application.register("scan", ScanController)
application.register("spinner", SpinnerController)
application.register("modal", ImageModalController)
application.register("memo-modal", MemoModalController)
application.register("image-upload", ImageUploadController)

import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap  // グローバルにしたい場合
import * as Turbo from "@hotwired/turbo"
window.Turbo = Turbo

// 他のファイルから使えるようにする場合（省略可）
export { application }