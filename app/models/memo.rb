class Memo < ApplicationRecord
  include RandomSelectable
  belongs_to :user
  belongs_to :book

  VISIBILITY = {
    only_me: 0,
    link_only: 1,
    public_site: 2
  }.freeze

  before_save :ensure_public_token_if_shared

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
  scope :exclude_user, ->(user) { user.present? ? where.not(user_id: user.id) : all }
  scope :with_book_and_user_avatar, -> {
    includes(:book, user: { avatar_s3_attachment: :blob })
  }

  def self.random_published_memo
    published_to_others
      .with_book_and_user_avatar
      .random_1
  end

  def self.random_nine(exclude_user: nil)
    published_to_others
      .exclude_user(exclude_user)
      .with_book_and_user_avatar
      .random_9
  end
end
