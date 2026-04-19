import { Controller } from "@hotwired/stimulus";

type RegistrationOptionsResponse = {
  challenge: string;
  rp: {
    name: string;
    id: string;
  };
  user: {
    id: string;
    name: string;
    displayName: string;
  };
  pubKeyCredParams: PublicKeyCredentialParameters[];
  timeout?: number;
  excludeCredentials: Array<{
    type: string;
    id: string;
  }>;
  authenticatorSelection?: AuthenticatorSelectionCriteria;
  attestation?: AttestationConveyancePreference;
};

export default class WebauthnRegistrationController extends Controller<HTMLElement> {
  static values = {
    redirectUrl: String,
  };

  declare redirectUrlValue: string;
  private preparedOptions: RegistrationOptionsResponse | null = null;
  private optionsRequest: Promise<RegistrationOptionsResponse> | null = null;

  connect(): void {
    // WebKit 系は click 内で fetch を挟むと user gesture を失いやすいため、
    // 先に登録オプションを取得しておく。
    void this.prepare();
  }

  async prepare(): Promise<void> {
    try {
      await this.loadOptions();
    } catch (error) {
      console.warn("WebAuthn 登録オプションの事前取得に失敗:", error);
    }
  }

  async register(): Promise<void> {
    try {
      const options = await this.loadOptions();

      // 1. Base64 デコード
      const challenge = this.base64ToArrayBuffer(options.challenge);
      const userId = this.base64ToArrayBuffer(options.user.id);
      const excludeCredentials = options.excludeCredentials.map(
        (cred: { type: string; id: string }) => ({
          type: cred.type as PublicKeyCredentialType,
          id: this.base64ToArrayBuffer(cred.id),
        })
      );

      // 2. WebAuthn API を呼び出し
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

      // 3. レスポンスを整形
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

      // 4. サーバーに送信して検証
      const verifyResponse = await fetch("/users/credentials", {
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
      this.preparedOptions = null;
      console.error("WebAuthn 登録エラー:", error);
      alert("エラーが発生しました。再度お試しください。");
    }
  }

  private async loadOptions(): Promise<RegistrationOptionsResponse> {
    if (this.preparedOptions) {
      return this.preparedOptions;
    }

    if (this.optionsRequest) {
      return this.optionsRequest;
    }

    this.optionsRequest = fetch("/users/credentials/new", {
      method: "GET",
      cache: "no-store",
      headers: {
        "Content-Type": "application/json",
      },
    })
      .then(async (response) => {
        if (!response.ok) {
          throw new Error("登録オプションの取得に失敗しました。");
        }

        return (await response.json()) as RegistrationOptionsResponse;
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
