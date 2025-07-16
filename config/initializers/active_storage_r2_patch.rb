require "active_storage/service/s3_service"
require "marcel"

Rails.application.config.to_prepare do
  module ActiveStorageR2UploadPatch
    def upload(key, io, checksum: nil, **_options) # ← optionsを無視
      instrument :upload, key: key, checksum: checksum do
        object = object_for(key)

        content_type = Marcel::MimeType.for(io, name: key) || "application/octet-stream"

        # 🔒 optionsは完全に自前で構成
        object.put(
          body: io,
          content_type: content_type
        )
      end
    end
  end

  ActiveStorage::Service::S3Service.prepend(ActiveStorageR2UploadPatch)
end
