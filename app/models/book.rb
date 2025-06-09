class Book < ApplicationRecord
  include PgSearch::Model
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
  validate :book_cover_format_valid?

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

  def book_cover_format_valid?
    return unless book_cover_s3.attached?

    allowed_extensions = %w[jpg jpeg png gif webp svg]
    allowed_content_types = %w[image/jpeg image/png image/gif image/webp image/svg+xml]

    extension = book_cover_s3.filename.extension_without_delimiter&.downcase
    content_type = book_cover_s3.content_type

    unless allowed_extensions.include?(extension) && allowed_content_types.include?(content_type)
      errors.add(:book_cover_s3, "は許可されていない形式です（jpg, png, gif, webp, svg）")
    end
  end
end
