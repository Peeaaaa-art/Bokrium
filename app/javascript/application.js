import { Application } from "@hotwired/stimulus"
import BarcodeController from "./controllers/barcode_controller"
import ScanController from "./controllers/scan_controller"
import SpinnerController from "./controllers/spinner_controller"
import MemoModalController from "./controllers/memo_modal_controller"
import ModalSwipeController from "./controllers/modal_swipe_controller"
import ConfirmModalController from "./controllers/confirm_modal_controller"
import ImageUploadController from "./controllers/image_upload_controller"
import TagToggleController from "./controllers/tag_toggle_controller"
import UiToggleController from "./controllers/ui_toggle_controller"
import ColumnSelectorController from "./controllers/column_selector_controller.js"
import AutoRemoveController from "./controllers/auto_remove_controller.js"
import AutoSubmitController from "./controllers/auto_submit_controller.js"

const application = Application.start()
window.Stimulus = application

application.register("barcode", BarcodeController)
application.register("scan", ScanController)
application.register("spinner", SpinnerController)
application.register("memo-modal", MemoModalController)
application.register("image-upload", ImageUploadController)
application.register("modal-swipe", ModalSwipeController)
application.register("confirm-modal", ConfirmModalController)
application.register("tag-toggle", TagToggleController)
application.register("ui-toggle", UiToggleController)
application.register("column-selector", ColumnSelectorController)
application.register("auto-remove", AutoRemoveController)
application.register("auto-submit", AutoSubmitController)


import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap  // グローバルにしたい場合
import * as Turbo from "@hotwired/turbo"
window.Turbo = Turbo

import { createIcons, icons } from "lucide"

document.addEventListener("turbo:load", () => {
  createIcons({ icons })  // ✅ すべてのアイコンを登録
})

export { application }
