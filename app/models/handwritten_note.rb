class HandwrittenNote < ApplicationRecord
  # Excalidrawのシーン全体をdataに保存するため、肥大化だけ防ぐ
  MAX_DATA_BYTESIZE = 2.megabytes

  belongs_to :user
  belongs_to :book

  validates :title, length: { maximum: 100, message: ": タイトルは100文字以内で入力してください" }, allow_blank: true
  validate :validate_data_structure

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
end
