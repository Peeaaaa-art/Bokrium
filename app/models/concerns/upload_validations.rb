module UploadValidations
  extend ActiveSupport::Concern

  included do
    validate :validate_upload_file_type
  end

  ALLOWED_EXTENSIONS = %w[jpg jpeg png gif webp svg].freeze
  ALLOWED_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    image/webp
    image/svg+xml
  ].freeze

  private

  def validate_upload_file_type
    attached_attributes = self.class.upload_validation_targets

    attached_attributes.each do |attribute|
      file = send(attribute)
      next unless file.attached?

      extension = file.filename.extension_without_delimiter&.downcase
      content_type = file.content_type

      unless ALLOWED_EXTENSIONS.include?(extension) && ALLOWED_CONTENT_TYPES.include?(content_type)
        errors.add(attribute, "は許可されていない形式です（jpg, png, gif, webp, svg）")
      end
    end
  end

  module ClassMethods
    def validate_uploads_for(*attributes)
      class_attribute :upload_validation_targets
      self.upload_validation_targets = attributes
    end
  end
end
