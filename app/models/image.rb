class Image < ApplicationRecord
  belongs_to :book
  has_one_attached :image_path, dependent: :purge_later

  validate :image_path_format_valid?

    private

    def image_path_format_valid?
      return unless image_path.attached?

      allowed_extensions = %w[jpg jpeg png gif webp svg]
      allowed_content_types = %w[image/jpeg image/png image/gif image/webp image/svg+xml]

      extension = image_path.filename.extension_without_delimiter&.downcase
      content_type = image_path.content_type

      unless allowed_extensions.include?(extension) && allowed_content_types.include?(content_type)
        errors.add(:image_path, "は許可されていない形式です（jpg, png, gif, webp, svg）")
      end
    end
end
