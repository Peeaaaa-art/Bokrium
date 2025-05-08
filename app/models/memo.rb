class Memo < ApplicationRecord
  include RandomSelectable
  belongs_to :user
  belongs_to :book

  enum :published, { only_i_can_see: 0, you_can_see: 1 }

  scope :published_to_others, -> { where(published: :you_can_see) }
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
