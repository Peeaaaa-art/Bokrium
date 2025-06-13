class SearchTerm < ApplicationRecord
  belongs_to :user

  validates :term, length: { maximum: 255, message: ": 255文字以内で入力してください" }
end
