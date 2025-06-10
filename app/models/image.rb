class Image < ApplicationRecord
  include UploadValidations
  belongs_to :book
  has_one_attached :image_path, dependent: :purge_later

  validate :validate_image_path_format

  private

  def validate_image_path_format
    validate_upload_format(image_path, :image_path)
  end
end
