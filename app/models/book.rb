class Book < ApplicationRecord
  include PgSearch::Model
  include UploadValidations
  before_validation :normalize_isbn
  before_save :record_started_on_when_reading

  belongs_to :user
  has_one_attached :book_cover_s3, service: :cloudflare_r2, dependent: :purge
  has_many :memos, dependent: :destroy
  has_many :images, dependent: :destroy
  has_many :handwritten_notes, dependent: :destroy
  has_many :book_tag_assignments, dependent: :destroy
  has_many :user_tags, through: :book_tag_assignments

  enum :status, {
    want_to_read: 0, # 読みたい
    reading: 1,      # 読書中
    finished: 2      # 読了
  }

  validates :title, presence: { message: ": タイトルは必須です" }, length: { maximum: 100, message: ": タイトルは100文字以内で入力してください" }
  validates :author, length: { maximum: 100, message: ": 著者は100文字以内で入力してください"  }, allow_blank: true
  validates :publisher, length: { maximum: 50,  message: ": 出版社は50文字以内で入力してください"  }, allow_blank: true
  validates :page,
          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 50_560, message: ": ページ数は50560ページ以下で入力してください" },
          allow_blank: true
  validates :current_page,
          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 50_560, message: ": 現在のページは50560ページ以下で入力してください" },
          allow_nil: true
  validates :price,
          numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1_000_000, message: ": 金額は100万円以下で指定してください" },
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

    if book_cover_s3.blob.service_name.to_s == "cloudflare_r2"
      cdn_domain = Rails.env.development? ? "dev-cdn.bokrium.com" : "cdn.bokrium.com"
      "https://#{cdn_domain}/#{book_cover_s3.key}"
    else
      Rails.application.routes.url_helpers.rails_blob_url(book_cover_s3, only_path: false)
    end
  end

  # 読書戦略ボード用の算出メソッド群。target_finish_on / current_page /
  # page はいずれも未設定(nil / 0)を取りうるため、常に nil 安全に扱う。

  # 進捗率(0.0〜1.0)。総ページ数か現在ページが不明なら nil
  def reading_progress_ratio
    return nil if page.to_i <= 0 || current_page.nil?

    (current_page.to_f / page).clamp(0.0, 1.0)
  end

  # 残りページ数。総ページ数か現在ページが不明なら nil
  def pages_remaining
    return nil if page.to_i <= 0 || current_page.nil?

    [ page - current_page, 0 ].max
  end

  # 目標日までの残り日数(過ぎていれば負)。目標日未設定なら nil
  def days_remaining(from: Date.current)
    return nil if target_finish_on.nil?

    (target_finish_on - from).to_i
  end

  # 目標日までに1日あたり何ページ読めば間に合うか。算出不能なら nil
  def required_daily_pages(from: Date.current)
    remaining = pages_remaining
    days = days_remaining(from: from)
    return nil if remaining.nil? || days.nil?
    return remaining if days <= 0 # 当日・超過分は残り全部が必要ペース

    (remaining.to_f / days).ceil
  end

  # 読書スケジュールの状態を表すシンボル
  def reading_schedule_status(from: Date.current)
    return :finished if finished?
    return :no_target if target_finish_on.nil?

    days = days_remaining(from: from)
    return :overdue if days.negative?
    return :due_today if days.zero?

    :on_track
  end

  # 読書戦略ボードの並び順: 読了目標日の近い順(未設定は末尾)
  scope :by_reading_deadline, -> {
    order(Arel.sql("target_finish_on ASC NULLS LAST")).order(:created_at)
  }

  scope :autocomplete_title_or_author, ->(term) {
    where("title ILIKE ? OR author ILIKE ?", "#{term}%", "#{term}%")
      .select(:id, :title, :author)
      .limit(10)
  }

  pg_search_scope :search_by_title_and_author,
                  against: [ :title, :author ],
                  using: {
                    tsearch: { prefix: true },
                    trigram: { threshold: 0.3 }
                  }


  scope :fuzzy_title_or_author, ->(query) {
    where("title ILIKE :q OR author ILIKE :q", q: "%#{sanitize_sql_like(query)}%")
  }

  private

  def normalize_isbn
    self.isbn = nil if isbn.blank?
  end

  # ステータスが「読書中」になったとき、読書開始日を自動記録する。
  # ユーザーが自分で設定・編集した値は上書きしない
  def record_started_on_when_reading
    return unless will_save_change_to_status? && reading?

    self.started_on ||= Date.current
  end
end
