class Book < ApplicationRecord
  belongs_to :user
  has_many :memos, dependent: :destroy
  has_many :book_tags, dependent: :destroy
  has_many :tags, through: :book_tags
  mount_uploader :book_cover, BookCoverUploader
  has_many :images, dependent: :destroy

  enum :status, {
    want_to_read: 0, # 読みたい
    reading: 1,     # 読書中
    finished: 2    # 読了
  }
end
