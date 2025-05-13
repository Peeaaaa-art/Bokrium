class Book < ApplicationRecord
  include PgSearch::Model

  belongs_to :user
  has_one_attached :book_cover_s3, dependent: :purge_later
  has_many :memos, dependent: :destroy
  has_many :images, dependent: :destroy
  acts_as_taggable_on :tags

  enum :status, {
    want_to_read: 0, # 読みたい
    reading: 1,      # 読書中
    finished: 2      # 読了
  }

  validates :isbn, uniqueness: { scope: :user_id, message: "この書籍はMy本棚に登録済みです" }, allow_blank: true

  pg_search_scope :search_by_title_and_author,
                  against: [ :title, :author ],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.03 }
                  }
end
