// --- Styles ---
import "bootstrap/dist/css/bootstrap.css";
import "bootstrap-icons/font/bootstrap-icons.css";
import "../styles/application.scss";

// --- JavaScript Modules ---

import { Application } from "@hotwired/stimulus"
import * as Turbo from "@hotwired/turbo"
import * as bootstrap from "bootstrap"
import { createIcons } from "lucide"
import {
  BookOpen,
  BookOpenText,
  LibraryBig,
  Users,
  Search,
} from "lucide"

import AnimationController from "./controllers/animation_controller"
import AutoCompleteController from "./controllers/autocomplete_controller"
import AutoRemoveController from "./controllers/auto_remove_controller"
import AutoSubmitController from "./controllers/auto_submit_controller"
import BarcodeController from "./controllers/barcode_controller"
import BookEditController from "./controllers/book_edit_controller"
import ColumnSelectorController from "./controllers/column_selector_controller"
import ConfirmModalController from "./controllers/confirm_modal_controller"
import DetailCardColumnSelectorController from "./controllers/detail_card_column_selector_controller"
import ImageUploadController from "./controllers/image_upload_controller"
import LazyLoadController from "./controllers/lazy_load_controller"
import MemoModalController from "./controllers/memo_modal_controller"
import ModalSwipeController from "./controllers/modal_swipe_controller"
import PaginationScrollController from "./controllers/pagination_scroll_controller"
import SafariClickFixController from "./controllers/safari_click_fix_controller"
import ScanController from "./controllers/scan_controller"
import SpinnerController from "./controllers/spinner_controller"
import SpineBookController from "./controllers/spine_book_controller"
import TagToggleController from "./controllers/tag_toggle_controller"
import UiToggleController from "./controllers/ui_toggle_controller"

// --- Stimulus Application ---
const application = Application.start()
window.Stimulus = application

application.register("animation", AnimationController)
application.register("autocomplete", AutoCompleteController)
application.register("auto-remove", AutoRemoveController)
application.register("auto-submit", AutoSubmitController)
application.register("barcode", BarcodeController)
application.register("book-edit", BookEditController)
application.register("column-selector", ColumnSelectorController)
application.register("confirm-modal", ConfirmModalController)
application.register("detail-card-column-selector", DetailCardColumnSelectorController)
application.register("image-upload", ImageUploadController)
application.register("lazy-load", LazyLoadController)
application.register("memo-modal", MemoModalController)
application.register("modal-swipe", ModalSwipeController)
application.register("pagination-scroll", PaginationScrollController)
application.register("safari-click-fix", SafariClickFixController)
application.register("scan", ScanController)
application.register("spinner", SpinnerController)
application.register("spine-book", SpineBookController)
application.register("tag-toggle", TagToggleController)
application.register("ui-toggle", UiToggleController)

// --- Global Dependencies ---
window.bootstrap = bootstrap
window.Turbo = Turbo

// --- Custom JS ---
import "./readonly_editor.jsx"

// --- Lucide icons ---
const iconSet = {
  BookOpen,
  BookOpenText,
  LibraryBig,
  Users,
  Search,
}

createIcons({ icons: iconSet, attrs: { "aria-hidden": "true" } })

document.addEventListener("turbo:load", () => {
  createIcons({ icons: iconSet, attrs: { "aria-hidden": "true" } })
})

export { application }