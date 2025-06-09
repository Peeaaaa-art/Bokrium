# app/models/concerns/upload_validations.rb
module UploadValidations
  extend ActiveSupport::Concern

  MAX_UPLOAD_SIZE = 1.megabytes

  def validate_upload_format(attachment, attribute_name)
    return unless attachment.attached?

    allowed_extensions = %w[jpg jpeg png gif webp svg]
    allowed_content_types = %w[image/jpeg image/png image/gif image/webp image/svg+xml]

    extension = attachment.filename.extension_without_delimiter&.downcase
    content_type = attachment.content_type

    unless allowed_extensions.include?(extension) && allowed_content_types.include?(content_type)
      errors.add(attribute_name, " : 許可されていない形式です（jpg, png, gif, webp, svg）")
    end

    if attachment.blob.byte_size > MAX_UPLOAD_SIZE
      errors.add(attribute_name, " : 10MB以下のファイルにしてください")
    end
  end
end
