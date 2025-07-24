// --- Styles ---
import "bootstrap/dist/css/bootstrap.css";
import "../styles/application.scss";


// --- JavaScript Modules ---
import { Application } from "@hotwired/stimulus";
import * as Turbo from "@hotwired/turbo";
import * as bootstrap from "bootstrap";

// --- グローバル型定義の追加 ---
declare global {
  interface TurboVisitOptions {
    frame?: string
    action?: "advance" | "replace" | "restore"
    historyChanged?: boolean
  }

  interface TurboController {
    visit(url: string, options?: TurboVisitOptions): void
  }

  interface Window {
    bootstrap: typeof bootstrap
    Turbo: typeof Turbo & TurboController
    Stimulus: Application
  }
}

// ✅ Turboにvisit追加 → 型安全に代入
window.Turbo = {
  ...Turbo,
  visit: (url: string, options?: TurboVisitOptions) => {
    const frame = options?.frame
    if (frame) {
      const frameElement = document.querySelector(`turbo-frame#${frame}`)
      if (frameElement instanceof HTMLElement) {
        frameElement.setAttribute("src", url)
        return
      }
    }
    window.location.href = url
  },
}

document.addEventListener("turbo:load", () => {
  const tooltipTriggerList = Array.from(
    document.querySelectorAll('[data-bs-toggle="tooltip"]')
  );

  tooltipTriggerList.forEach((el) => {
    const existingInstance = bootstrap.Tooltip.getInstance(el);
    if (existingInstance) {
      existingInstance.dispose();
    }

    new bootstrap.Tooltip(el);
  });
});

// --- Stimulus Controllers ---
import AnimationController from "./controllers/animation_controller";
import AutoCompleteController from "./controllers/autocomplete_controller";
import AutoRemoveController from "./controllers/auto_remove_controller";
import AutoSubmitController from "./controllers/auto_submit_controller";
import BarcodeResultController from "./controllers/barcode_result_controller";
import BarcodeScanController from "./controllers/barcode_scan_controller";
import BookEditController from "./controllers/book_edit_controller";
import ColumnSelectorController from "./controllers/column_selector_controller";
import ConfirmModalController from "./controllers/confirm_modal_controller";
import DetailCardColumnSelectorController from "./controllers/detail_card_column_selector_controller";
import ImageUploadController from "./controllers/image_upload_controller";
import LazyLoadController from "./controllers/lazy_load_controller";
import MemoModalController from "./controllers/memo_modal_controller";
import ModalSwipeController from "./controllers/modal_swipe_controller";
import SafariClickFixController from "./controllers/safari_click_fix_controller";
import ScrollTopOnClickController from "./controllers/scroll_top_on_click_controller";
import SpinnerController from "./controllers/spinner_controller";
import SpineBookController from "./controllers/spine_book_controller";
import TagToggleController from "./controllers/tag_toggle_controller";
import UiToggleController from "./controllers/ui_toggle_controller";

// --- Stimulus Application ---
const application = Application.start();
window.Stimulus = application;

application.register("animation", AnimationController);
application.register("autocomplete", AutoCompleteController);
application.register("auto-remove", AutoRemoveController);
application.register("auto-submit", AutoSubmitController);
application.register("barcode-result", BarcodeResultController);
application.register("barcode-scan", BarcodeScanController);
application.register("book-edit", BookEditController);
application.register("column-selector", ColumnSelectorController);
application.register("confirm-modal", ConfirmModalController);
application.register("detail-card-column-selector", DetailCardColumnSelectorController);
application.register("image-upload", ImageUploadController);
application.register("lazy-load", LazyLoadController);
application.register("memo-modal", MemoModalController);
application.register("modal-swipe", ModalSwipeController);
application.register("safari-click-fix", SafariClickFixController);
application.register("scroll-top-on-click", ScrollTopOnClickController);
application.register("spinner", SpinnerController);
application.register("spine-book", SpineBookController);
application.register("tag-toggle", TagToggleController);
application.register("ui-toggle", UiToggleController);

// --- Global Dependencies ---
window.bootstrap = bootstrap;
// visit を追加した Turbo オブジェクトだけを使う
window.Turbo = {
  ...Turbo,
  visit: (url: string, options?: TurboVisitOptions) => {
    const frame = options?.frame;
    if (frame) {
      const frameElement = document.querySelector(`turbo-frame#${frame}`);
      if (frameElement instanceof HTMLElement) {
        frameElement.setAttribute("src", url);
        return;
      }
    }
    window.location.href = url;
  },
};

// --- Custom JS ---
import "./readonly_editor";

export { application };