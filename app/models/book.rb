class Book < ApplicationRecord
  include PgSearch::Model
  include UploadValidations
  before_validation :normalize_isbn

  belongs_to :user
  has_one_attached :book_cover_s3, dependent: :purge_later
  has_many :memos, dependent: :destroy
  has_many :images, dependent: :destroy
  has_many :book_tag_assignments, dependent: :destroy
  has_many :user_tags, through: :book_tag_assignments

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

  def bokrium_cover_url
    return nil unless book_cover_s3.attached? && book_cover_s3.key.present?

    if use_r2_cover?
      "https://cdn.bokrium.com/#{book_cover_s3.key}"
    elsif use_s3_cover?
      "https://img.bokrium.com/#{book_cover_s3.key}"
    else
      Rails.application.routes.url_helpers.rails_blob_url(book_cover_s3, only_path: false)
    end
  end

  scope :autocomplete_title_or_author, ->(term) {
    where("title ILIKE ? OR author ILIKE ?", "#{term}%", "#{term}%")
      .select(:id, :title, :author)
      .limit(10)
  }

  pg_search_scope :search_by_title_and_author,
                  against: [ :title, :author ],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.03 }
                  }

  scope :fuzzy_title_or_author, ->(query) {
    where("title ILIKE :q OR author ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  private

  def normalize_isbn
    self.isbn = nil if isbn.blank?
  end

  def use_s3_cover?
    book_cover_s3.attached? && book_cover_s3.blob.service_name.to_s == "amazon"
  end

  def use_r2_cover?
    book_cover_s3.attached? && book_cover_s3.blob.service_name.to_s == "cloudflare_r2"
  end
end
