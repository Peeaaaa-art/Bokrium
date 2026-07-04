class HandwrittenNote < ApplicationRecord
  include UploadValidations

  # Excalidrawのシーン全体をdataに保存するため、肥大化だけ防ぐ
  MAX_DATA_BYTESIZE = 2.megabytes

  belongs_to :user
  belongs_to :book

  has_one_attached :thumbnail_s3,
    service: (Rails.env.test? ? :test : :cloudflare_private_r2),
    dependent: :purge

  scope :ordered, -> { order(:position, :id) }

  validates :title, length: { maximum: 100, message: ": タイトルは100文字以内で入力してください" }, allow_blank: true
  validate :validate_data_structure
  validate :validate_thumbnail_format

  def display_title
    title.presence || "手書きノート"
  end

  private

  def validate_data_structure
    unless data.is_a?(Hash)
      errors.add(:data, ": 手書きデータの形式が不正です")
      return
    end

    if data.to_json.bytesize > MAX_DATA_BYTESIZE
      errors.add(:data, ": 手書きデータが大きすぎます（2MBまで）")
    end
  end

  def validate_thumbnail_format
    validate_upload_format(thumbnail_s3, :thumbnail_s3)
  end
end
