import { Controller } from "@hotwired/stimulus";

type LoginOptionsResponse = {
  challenge: string;
  timeout?: number;
  rpId?: string;
  allowCredentials: Array<{
    id: string;
    type: string;
    transports?: AuthenticatorTransport[];
  }>;
  userVerification?: UserVerificationRequirement;
};

export default class WebauthnLoginController extends Controller<HTMLElement> {
  private preparedOptions: LoginOptionsResponse | null = null;
  private optionsRequest: Promise<LoginOptionsResponse> | null = null;

  connect(): void {
    // Safari / WebKit では click 内の非同期 fetch 後に get() を呼ぶと
    // user gesture を失って失敗しやすいため、先に options を取っておく。
    void this.prepare();
  }

  async prepare(): Promise<void> {
    try {
      await this.loadOptions();
    } catch (error) {
      console.warn("WebAuthn 認証オプションの事前取得に失敗:", error);
    }
  }

  async login(): Promise<void> {
    try {
      const options = await this.loadOptions();

      // 1. Base64 デコード
      const challenge = this.base64ToArrayBuffer(options.challenge);
      const allowCredentials = options.allowCredentials.map((credential) => ({
        ...credential,
        type: credential.type as PublicKeyCredentialType,
        id: this.base64ToArrayBuffer(credential.id),
      }));

      // 2. WebAuthn API を呼び出し
      const credential = (await navigator.credentials.get({
        publicKey: {
          challenge,
          timeout: options.timeout,
          rpId: options.rpId,
          allowCredentials,
          userVerification: options.userVerification || "preferred",
        },
      })) as PublicKeyCredential | null;

      if (!credential) {
        alert("認証がキャンセルされました。");
        return;
      }

      // 3. レスポンスを整形
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

      // 4. サーバーに送信して検証
      const verifyResponse = await fetch("/users/webauthn_login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCSRFToken(),
        },
        body: JSON.stringify(body),
      });

      this.preparedOptions = null;

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
      this.preparedOptions = null;
      console.error("WebAuthn ログインエラー:", error);
      alert("エラーが発生しました。再度お試しください。");
    }
  }

  private async loadOptions(): Promise<LoginOptionsResponse> {
    if (this.preparedOptions) {
      return this.preparedOptions;
    }

    if (this.optionsRequest) {
      return this.optionsRequest;
    }

    this.optionsRequest = fetch("/users/webauthn_login", {
      method: "GET",
      cache: "no-store",
      headers: {
        "Content-Type": "application/json",
      },
    })
      .then(async (response) => {
        if (!response.ok) {
          throw new Error("認証オプションの取得に失敗しました。");
        }

        return (await response.json()) as LoginOptionsResponse;
      })
      .then((options) => {
        this.preparedOptions = options;
        return options;
      })
      .finally(() => {
        this.optionsRequest = null;
      });

    return this.optionsRequest;
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
