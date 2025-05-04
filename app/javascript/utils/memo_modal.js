// app/javascript/utils/memo_modal.js
export function discardChanges() {
  window.hasUnsavedChanges = false
  bootstrap.Modal.getInstance(document.getElementById("memoEditModal"))?.hide()
}

export function saveAndClose() {
  document.getElementById("memo-edit-form").requestSubmit()
  window.hasUnsavedChanges = false
  bootstrap.Modal.getInstance(document.getElementById("memoEditModal"))?.hide()
}