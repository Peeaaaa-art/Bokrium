class Book < ApplicationRecord
  include PgSearch::Model
  include UploadValidations
  before_validation :normalize_isbn

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
  validates :title, presence: { message: ": タイトルは必須です" }
  validates :isbn, uniqueness: { scope: :user_id, message: ": この書籍は本棚に登録済みです" }, allow_blank: true
  validate :validate_book_cover_format

  def validate_book_cover_format
    validate_upload_format(book_cover_s3, :book_cover_s3)
  end

  pg_search_scope :search_by_title_and_author,
                  against: [ :title, :author ],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.03 }
                  }

  private

  def normalize_isbn
    self.isbn = nil if isbn.blank?
  end
end
