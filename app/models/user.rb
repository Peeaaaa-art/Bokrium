class User < ApplicationRecord
  has_one_attached :avatar_s3, dependent: :purge_later
  has_many :books, dependent: :destroy
  has_many :memos, dependent: :destroy
  has_many :tags, class_name: 'ActsAsTaggableOn::Tag'
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable
end
