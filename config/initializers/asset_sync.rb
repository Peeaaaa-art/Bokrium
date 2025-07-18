if defined?(AssetSync)
  AssetSync.configure do |config|
    config.enabled = Rails.env.production?

    config.fog_provider = "AWS"
    config.aws_access_key_id     = ENV["R2_ACCESS_KEY_ID"]
    config.aws_secret_access_key = ENV["R2_SECRET_ACCESS_KEY"]
    config.fog_directory = ENV["R2_BUCKET"]           # 例: bokrium-cdn
    config.fog_region = "auto"                        # R2では region は 'auto'

    # Cloudflare R2 固有の endpoint
    config.fog_options = {
      endpoint: ENV["R2_ENDPOINT"],                   # 例: https://<account-id>.r2.cloudflarestorage.com
      path_style: true
    }

    config.gzip_compression = true
    config.manifest = true
    config.fail_silently = false
  end
end
