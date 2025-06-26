class UserTag < ApplicationRecord
  belongs_to :user
  has_many :book_tag_assignments, dependent: :destroy
  has_many :books, through: :book_tag_assignments

  validates :name, presence: true, uniqueness: { scope: :user_id }, length: { maximum: 30 }

  scope :owned_by, ->(user) { where(user: user) }
end
