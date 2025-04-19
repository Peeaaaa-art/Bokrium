class Book < ApplicationRecord
  belongs_to :user
  has_many :memos, dependent: :destroy
  has_many :tags
end
