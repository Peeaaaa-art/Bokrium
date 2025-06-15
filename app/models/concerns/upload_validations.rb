module UploadValidations
  extend ActiveSupport::Concern

  MAX_UPLOAD_SIZE = 5.megabytes

  def validate_upload_format(attachment, attribute_name)
    return unless attachment.attached?

    allowed_extensions = %w[jpg jpeg png gif webp svg]
    allowed_content_types = %w[image/jpeg image/png image/gif image/webp image/svg+xml]

    extension = attachment.filename.extension_without_delimiter&.downcase
    content_type = attachment.content_type

    # content_type が許可されていれば、拡張子が無くても許可する
    if !allowed_content_types.include?(content_type)
      errors.add(attribute_name, " : 許可されていない形式です（jpg, png, gif, webp, svg）")
    elsif extension.present? && !allowed_extensions.include?(extension)
      errors.add(attribute_name, " : ファイル拡張子が不正です（jpg, png, gif, webp, svg）")
    end

    if attachment.blob.byte_size > MAX_UPLOAD_SIZE
      errors.add(attribute_name, " : 5MB以下のファイルにしてください")
    end
  end
end
