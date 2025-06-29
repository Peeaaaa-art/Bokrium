class BookTagAssignment < ApplicationRecord
  belongs_to :user
  belongs_to :book
  belongs_to :user_tag

  validates :user_id, presence: true
  validates :book_id, uniqueness: { scope: :user_tag_id }
end
