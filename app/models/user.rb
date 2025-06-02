class User < ApplicationRecord
  has_one :line_user, dependent: :destroy
  has_one_attached :avatar_s3, dependent: :purge_later
  has_many :books, dependent: :destroy
  has_many :memos, dependent: :destroy
  has_many :tags, class_name: "ActsAsTaggableOn::Tag", dependent: :destroy
  has_many :like_memos, dependent: :destroy
  has_many :liked_memos, through: :like_memos, source: :memo
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable
  devise :database_authenticatable, :registerable,
        :recoverable, :rememberable, :validatable, :confirmable,
        :omniauthable, omniauth_providers: [:line]
  def self.from_omniauth(auth)
    line_id = auth["uid"]
    line_name = auth["info"]["name"]

    line_user = LineUser.find_by(line_id: line_id)

    if line_user
      line_user.user
    else
      user = User.create!(
        name: line_name.presence || "LINE User",
        email: "#{line_id}@example.com",
        password: Devise.friendly_token[0, 20],
        confirmed_at: Time.current # メール確認をスキップ
      )

      user.create_line_user!(
        line_id: line_id,
        line_name: line_name
      )

      user
    end
  end
end
