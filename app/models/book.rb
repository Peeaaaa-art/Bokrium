class Book < ApplicationRecord
  belongs_to :user
  has_one_attached :book_cover_s3, dependent: :purge_later
  has_many :memos, dependent: :destroy
  has_many :book_tags, dependent: :destroy
  has_many :tags, through: :book_tags
  has_many :images, dependent: :destroy

  enum :status, {
    want_to_read: 0, # 読みたい
    reading: 1,     # 読書中
    finished: 2    # 読了
  }
end
