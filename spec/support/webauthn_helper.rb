module WebAuthnHelper
  # WebAuthn の登録オプションをモック
  def mock_webauthn_create_options
    challenge = SecureRandom.random_bytes(32)
    challenge_b64 = Base64.urlsafe_encode64(challenge, padding: false)

    rp_mock = OpenStruct.new(id: "localhost", name: "Bokrium")
    user_mock = OpenStruct.new(id: "1", name: "test@example.com", display_name: "Test User")

    options = OpenStruct.new(
      challenge: challenge,
      rp: rp_mock,
      user: user_mock,
      exclude: [],
      timeout: 60000,
      pub_key_cred_params: []
    )

    {
      challenge: challenge,
      challenge_b64: challenge_b64,
      options: options
    }
  end

  # WebAuthn の認証オプションをモック
  def mock_webauthn_get_options
    challenge = SecureRandom.random_bytes(32)
    challenge_b64 = Base64.urlsafe_encode64(challenge, padding: false)

    {
      challenge: challenge,
      challenge_b64: challenge_b64,
      options: double(
        challenge: challenge,
        timeout: 60000
      )
    }
  end

  # WebAuthn の登録レスポンスをモック
  def mock_webauthn_credential_create(challenge:)
    raw_id = SecureRandom.random_bytes(16)
    public_key = SecureRandom.random_bytes(65)

    credential = double(
      id: Base64.urlsafe_encode64(raw_id, padding: false),
      raw_id: raw_id,
      type: "public-key",
      public_key: Base64.strict_encode64(public_key),
      sign_count: 0,
      response: double(
        attestation_object: "fake_attestation_object",
        client_data_json: "fake_client_data_json"
      )
    )

    allow(WebAuthn::Credential).to receive(:from_create).and_return(credential)
    allow(credential).to receive(:verify).with(anything).and_return(true)

    {
      credential: credential,
      raw_id: raw_id,
      public_key: public_key,
      params: {
        id: Base64.urlsafe_encode64(raw_id, padding: false),
        rawId: Base64.urlsafe_encode64(raw_id, padding: false),
        type: "public-key",
        response: {
          attestationObject: Base64.urlsafe_encode64("fake_attestation_object", padding: false),
          clientDataJSON: Base64.urlsafe_encode64("fake_client_data_json", padding: false)
        }
      }
    }
  end

  # WebAuthn の認証レスポンスをモック
  def mock_webauthn_credential_get(credential:, challenge:)
    authenticator_data = SecureRandom.random_bytes(37)
    signature = SecureRandom.random_bytes(70)

    webauthn_credential = double(
      id: Base64.urlsafe_encode64(Base64.strict_decode64(credential.external_id), padding: false),
      raw_id: Base64.strict_decode64(credential.external_id),
      type: "public-key",
      sign_count: credential.sign_count + 1,
      response: double(
        authenticator_data: authenticator_data,
        client_data_json: "fake_client_data_json",
        signature: signature,
        user_handle: credential.user_id.to_s
      )
    )

    allow(WebAuthn::Credential).to receive(:from_get).and_return(webauthn_credential)
    allow(webauthn_credential).to receive(:verify).with(
      anything,
      hash_including(public_key: credential.public_key, sign_count: credential.sign_count)
    ).and_return(true)

    {
      credential: webauthn_credential,
      params: {
        id: Base64.urlsafe_encode64(Base64.strict_decode64(credential.external_id), padding: false),
        rawId: Base64.urlsafe_encode64(Base64.strict_decode64(credential.external_id), padding: false),
        type: "public-key",
        response: {
          authenticatorData: Base64.urlsafe_encode64(authenticator_data, padding: false),
          clientDataJSON: Base64.urlsafe_encode64("fake_client_data_json", padding: false),
          signature: Base64.urlsafe_encode64(signature, padding: false),
          userHandle: Base64.urlsafe_encode64(credential.user_id.to_s, padding: false)
        }
      }
    }
  end
end
