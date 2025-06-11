class Image < ApplicationRecord
  include UploadValidations
  belongs_to :book
  has_one_attached :image_path, dependent: :purge_later

  validate :validate_image_path_format
  validate :within_limit_for_free_plan, on: :create

  private

  def validate_image_path_format
    validate_upload_format(image_path, :image_path)
  end

  def within_limit_for_free_plan
    return if user.nil? || book.user.bokrium_premium?

    user_images_count = Image.joins(:book).where(books: { user_id: book.user.id }).count
    if user_images_count >= BokriumLimit::FREE[:images]
      errors.add(:base, :limit_exceeded, message: "無料プランの画像アップロード上限#{BokriumLimit::FREE[:images]}枚に達しました。")
    end
  end
end
