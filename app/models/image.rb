class Image < ApplicationRecord
  include UploadValidations
  belongs_to :book
  has_one_attached :image_s3, service: :cloudflare_private_r2, dependent: :purge

  validate :validate_image_format

  private

  def validate_image_format
    validate_upload_format(image_s3, :image_s3)
  end
end
