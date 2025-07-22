class Memo < ApplicationRecord
  include PgSearch::Model
  include RandomSelectable

  belongs_to :user
  belongs_to :book
  has_many :like_memos, dependent: :destroy
  has_many :liked_users, through: :like_memos, source: :user

  VISIBILITY = {
    only_me: 0,
    link_only: 1,
    public_site: 2
  }.freeze

  before_save :ensure_public_token_if_shared

  validates :content, length: { maximum: 10_000, message: ": メモは10,000文字以内で入力してください" }


  scope :published_to_others, -> { where(visibility: %i[link_only public_site]) }
  scope :publicly_listed, -> { where(visibility: VISIBILITY[:public_site]) }
  scope :exclude_user, ->(user) { user.present? ? where.not(user_id: user.id) : all }
  scope :with_book_and_user_avatar, -> { includes(:book, user: { avatar_s3_attachment: :blob }) }

  pg_search_scope :search_by_content,
  against: :content,
  using: {
    tsearch: {
      dictionary: "simple",
      prefix: true,
      any_word: true
    },
    trigram: {
      threshold: 0.1
    }
  }

  def ensure_public_token_if_shared
    if shared? && public_token.blank?
      self.public_token = SecureRandom.hex(10)
    end
  end

  def visibility
    VISIBILITY.key(self[:visibility])&.to_s
  end

  def visibility?(key)
    self[:visibility] == VISIBILITY[key.to_sym]
  end

  def shared?
    visibility?(:link_only) || visibility?(:public_site)
  end

  def publicly_listed?
    visibility?(:public_site)
  end

  def public_url
    return nil unless public_token.present?
    Rails.application.routes.url_helpers.public_bookshelf_url(public_token, host: default_host)
  end

  def default_host
    Rails.application.routes.default_url_options[:host] || "localhost:3000"
  end

  def self.publicly_listed_with_book_and_user(exclude_user: nil)
    publicly_listed
      .exclude_user(exclude_user)
      .with_book_and_user_avatar
      .includes(book: [ :book_cover_s3_attachment ])
      .order(created_at: :desc)
  end

  def self.random_public_memo
    publicly_listed
      .with_book_and_user_avatar
      .random_1
  end
end
