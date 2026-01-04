import { Controller } from "@hotwired/stimulus";

export default class WebauthnRegistrationController extends Controller<HTMLElement> {
  static values = {
    redirectUrl: String,
  };

  declare redirectUrlValue: string;

  async register(): Promise<void> {
    try {
      // 1. サーバーから challenge を取得
      const optionsResponse = await fetch("/users/credentials/new", {
        method: "GET",
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!optionsResponse.ok) {
        throw new Error("登録オプションの取得に失敗しました。");
      }

      const options = await optionsResponse.json();

      // 2. Base64 デコード
      const challenge = this.base64ToArrayBuffer(options.challenge);
      const userId = this.base64ToArrayBuffer(options.user.id);
      const excludeCredentials = options.excludeCredentials.map(
        (cred: { type: string; id: string }) => ({
          type: cred.type as PublicKeyCredentialType,
          id: this.base64ToArrayBuffer(cred.id),
        })
      );

      // 3. WebAuthn API を呼び出し
      const credential = (await navigator.credentials.create({
        publicKey: {
          challenge,
          rp: {
            name: options.rp.name,
            id: options.rp.id,
          },
          user: {
            id: userId,
            name: options.user.name,
            displayName: options.user.displayName,
          },
          pubKeyCredParams: options.pubKeyCredParams,
          timeout: options.timeout,
          excludeCredentials,
          authenticatorSelection: options.authenticatorSelection,
          attestation: options.attestation,
        },
      })) as PublicKeyCredential | null;

      if (!credential) {
        alert("登録がキャンセルされました。");
        return;
      }

      // 4. レスポンスを整形
      const response = credential.response as AuthenticatorAttestationResponse;
      const body = {
        id: credential.id,
        rawId: this.arrayBufferToBase64(credential.rawId),
        type: credential.type,
        response: {
          attestationObject: this.arrayBufferToBase64(response.attestationObject),
          clientDataJSON: this.arrayBufferToBase64(response.clientDataJSON),
        },
      };

      // 5. サーバーに送信して検証
      const verifyResponse = await fetch("/users/credentials", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCSRFToken(),
        },
        body: JSON.stringify(body),
      });

      if (!verifyResponse.ok) {
        const errorData = await verifyResponse.json();
        alert(errorData.error || "登録に失敗しました。");
        return;
      }

      const result = await verifyResponse.json();

      if (result.success) {
        // サーバーから返された redirect_to を優先的に使用
        if (result.redirect_to) {
          window.location.href = result.redirect_to;
        } else if (this.redirectUrlValue) {
          window.location.href = this.redirectUrlValue;
        } else {
          alert(result.message);
          // ページをリロードして反映
          window.location.reload();
        }
      } else {
        alert("登録に失敗しました。");
      }
    } catch (error) {
      console.error("WebAuthn 登録エラー:", error);
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
