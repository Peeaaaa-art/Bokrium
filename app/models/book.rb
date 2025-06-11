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
  validates :title, presence: { message: ": タイトルは必須です" }, length: { maximum: 100, message: ": タイトルは100文字以内で入力してください" }
  validates :author, length: { maximum: 50, message: ": 著者は50文字以内で入力してください"  }, allow_blank: true
  validates :publisher, length: { maximum: 50,  message: ": 出版社は50文字以内で入力してください"  }, allow_blank: true
  validates :page,
          numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 50_560, message: ": ページ数は50560ページ以下で入力してください" },
          allow_blank: true
  validates :price,
          numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 1_000_000, message: ": 金額は1円以上100万円以下で指定してください" },
          allow_blank: true
  validates :status,
            inclusion: { in: statuses.keys }
  validates :isbn, uniqueness: { scope: :user_id, message: ": この書籍は本棚に登録済みです" },
            format: {
            with: /\A[\dXx]{1,13}\z/,
            message: ": ISBNは数字とXのみで13文字以内で入力してください"
            }, allow_blank: true
  validate :validate_book_cover_format

  def validate_book_cover_format
    validate_upload_format(book_cover_s3, :book_cover_s3)
  end

  def cloudfront_url
    return nil unless book_cover_s3.attached? && book_cover_s3.key.present?

    "https://img.bokrium.com/#{book_cover_s3.key}"
  end

  pg_search_scope :search_by_title_and_author,
                  against: [ :title, :author ],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.03 }
                  }

  after_commit :enqueue_cover_download, on: :create

  private

  def normalize_isbn
    self.isbn = nil if isbn.blank?
  end

  def enqueue_cover_download
    return if book_cover.blank? || book_cover_s3.attached?

    DownloadCoverImageWorker.perform_async(id, book_cover)
  end
end
