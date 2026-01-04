import { Controller } from "@hotwired/stimulus";

export default class WebauthnLoginController extends Controller<HTMLElement> {
  async login(): Promise<void> {
    try {
      // 1. サーバーから challenge を取得
      const optionsResponse = await fetch("/users/webauthn_login", {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!optionsResponse.ok) {
        throw new Error("認証オプションの取得に失敗しました。");
      }

      const options = await optionsResponse.json();

      // 2. Base64 デコード
      const challenge = this.base64ToArrayBuffer(options.challenge);

      // 3. WebAuthn API を呼び出し
      const credential = (await navigator.credentials.get({
        publicKey: {
          challenge,
          timeout: options.timeout,
          rpId: options.rpId,
          allowCredentials: options.allowCredentials,
          userVerification: options.userVerification || "preferred",
        },
      })) as PublicKeyCredential | null;

      if (!credential) {
        alert("認証がキャンセルされました。");
        return;
      }

      // 4. レスポンスを整形
      const response = credential.response as AuthenticatorAssertionResponse;
      const body = {
        id: credential.id,
        rawId: this.arrayBufferToBase64(credential.rawId),
        type: credential.type,
        response: {
          authenticatorData: this.arrayBufferToBase64(response.authenticatorData),
          clientDataJSON: this.arrayBufferToBase64(response.clientDataJSON),
          signature: this.arrayBufferToBase64(response.signature),
          userHandle: response.userHandle
            ? this.arrayBufferToBase64(response.userHandle)
            : null,
        },
      };

      // 5. サーバーに送信して検証
      const verifyResponse = await fetch("/users/webauthn_login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCSRFToken(),
        },
        body: JSON.stringify(body),
      });

      if (!verifyResponse.ok) {
        const errorData = await verifyResponse.json();
        alert(errorData.error || "認証に失敗しました。");
        return;
      }

      const result = await verifyResponse.json();

      if (result.success) {
        // リダイレクト
        window.location.href = result.redirect_to;
      } else {
        alert("ログインに失敗しました。");
      }
    } catch (error) {
      console.error("WebAuthn ログインエラー:", error);
      alert("エラーが発生しました。再度お試しください。");
    }
  }

  // Helper: Base64 → ArrayBuffer
  private base64ToArrayBuffer(base64: string): ArrayBuffer {
    const binary = atob(base64.replace(/-/g, "+").replace(/_/g, "/"));
    const len = binary.length;
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binary.charCodeAt(i);
    }
    return bytes.buffer;
  }

  // Helper: ArrayBuffer → Base64
  private arrayBufferToBase64(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let binary = "";
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i]);
    }
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "");
  }

  // Helper: CSRF トークン取得
  private getCSRFToken(): string {
    const meta = document.querySelector<HTMLMetaElement>(
      'meta[name="csrf-token"]'
    );
    return meta ? meta.content : "";
  }
}
