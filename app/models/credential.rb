# frozen_string_literal: true

class Credential < ApplicationRecord
  belongs_to :user

  validates :external_id, presence: true, uniqueness: true
  validates :public_key, presence: true
  validates :sign_count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # ニックネームがなければデフォルト値を設定
  def display_name
    nickname.presence || "パスキー #{created_at.strftime('%Y/%m/%d')}"
  end
end
