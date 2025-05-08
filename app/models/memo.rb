class Memo < ApplicationRecord
  belongs_to :user
  belongs_to :book

  enum :published, { only_i_can_see: 0, you_can_see: 1 }

  scope :published_to_others, -> { where(published: :you_can_see) }
  scope :with_book_and_user_avatar, -> {
    includes(:book, user: { avatar_s3_attachment: :blob })
  }

  def self.random_published_memo
    published_to_others
      .with_book_and_user_avatar
      .order("RANDOM()")
      .first
  end
end
