// controllers/tag_collapse_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    const collapses = document.querySelectorAll(".collapse");
    collapses.forEach(el => el.classList.remove("show"));
  }
}