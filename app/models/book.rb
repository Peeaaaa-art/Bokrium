class Book < ApplicationRecord
  belongs_to :user
  has_many :memos, dependent: :destroy
  has_many :book_tags, dependent: :destroy
  has_many :tags, through: :book_tags
end
