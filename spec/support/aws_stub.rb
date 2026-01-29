# frozen_string_literal: true

# AWS EC2インスタンスプロファイルのメタデータエンドポイントへのリクエストをスタブ
# ActiveStorageでS3互換サービス(Cloudflare R2)を使用する際に必要
RSpec.configure do |config|
  config.before(:each) do
    # EC2メタデータトークン取得をスタブ
    stub_request(:put, "http://169.254.169.254/latest/api/token")
      .with(headers: { "X-Aws-Ec2-Metadata-Token-Ttl-Seconds" => "21600" })
      .to_return(status: 404, body: "", headers: {})

    # EC2メタデータ認証情報取得をスタブ
    stub_request(:get, %r{http://169\.254\.169\.254/latest/meta-data/iam/security-credentials/})
      .to_return(status: 404, body: "", headers: {})
  end
end
