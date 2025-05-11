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

  pg_search_scope :search_by_content,
  against: :content,
  using: {
    tsearch: {
      tsvector_column: "text_index",
      dictionary: "simple",
      prefix: true
    },
    trigram: {
      threshold: 0.05
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
    Rails.application.routes.url_helpers.shared_memo_url(public_token, host: default_host)
  end

  def default_host
    Rails.application.routes.default_url_options[:host] || "localhost:3000"
  end

  scope :published_to_others, -> { where(visibility: %i[link_only public_site]) }
  scope :publicly_listed, -> { where(visibility: VISIBILITY[:public_site]) }
  scope :exclude_user, ->(user) { user.present? ? where.not(user_id: user.id) : all }
  scope :with_book_and_user_avatar, -> {
    includes(:book, user: { avatar_s3_attachment: :blob })
  }

  def self.random_public_memo
    publicly_listed
      .with_book_and_user_avatar
      .random_1
  end

  def self.random_nine_public(exclude_user: nil)
    publicly_listed
      .exclude_user(exclude_user)
      .with_book_and_user_avatar
      .random_9
  end
end
