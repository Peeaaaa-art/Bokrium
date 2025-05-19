class User < ApplicationRecord
  has_one :line_user, dependent: :destroy
  has_one_attached :avatar_s3, dependent: :purge_later
  has_many :books, dependent: :destroy
  has_many :memos, dependent: :destroy
  has_many :tags, class_name: "ActsAsTaggableOn::Tag", dependent: :destroy
  has_many :like_memos, dependent: :destroy
  has_many :liked_memos, through: :like_memos, source: :memo
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable, :confirmable

  def guest_user?
    id == 999
  end
end
