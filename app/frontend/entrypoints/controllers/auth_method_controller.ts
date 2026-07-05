import { Controller } from "@hotwired/stimulus"

// 登録画面の認証方法(パスキー/パスワード)切替。
// パスワード選択時のみパスワード欄を表示し、required属性を付け替える
export default class AuthMethodController extends Controller<HTMLElement> {
  static targets = [
    "passkeyRadio",
    "passwordRadio",
    "passwordFields",
    "passkeyInfo",
    "passwordInput",
    "passwordConfirmInput",
  ]

  declare readonly passkeyRadioTarget: HTMLInputElement
  declare readonly passwordRadioTarget: HTMLInputElement
  declare readonly passwordFieldsTarget: HTMLElement
  declare readonly hasPasskeyInfoTarget: boolean
  declare readonly passkeyInfoTarget: HTMLElement
  declare readonly passwordInputTarget: HTMLInputElement
  declare readonly passwordConfirmInputTarget: HTMLInputElement

  connect() {
    if (this.passkeyRadioTarget.checked) this.selectPasskey()
  }

  selectPasskey() {
    this.passkeyRadioTarget.checked = true
    this.passwordFieldsTarget.style.display = "none"
    if (this.hasPasskeyInfoTarget) this.passkeyInfoTarget.style.display = "block"
    this.passwordInputTarget.removeAttribute("required")
    this.passwordConfirmInputTarget.removeAttribute("required")
    this.passwordInputTarget.value = ""
    this.passwordConfirmInputTarget.value = ""
  }

  selectPassword() {
    this.passwordRadioTarget.checked = true
    this.passwordFieldsTarget.style.display = "block"
    if (this.hasPasskeyInfoTarget) this.passkeyInfoTarget.style.display = "none"
    this.passwordInputTarget.setAttribute("required", "required")
    this.passwordConfirmInputTarget.setAttribute("required", "required")
  }
}
