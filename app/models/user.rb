class User < ApplicationRecord
  has_one :line_user, dependent: :destroy
  has_one_attached :avatar_s3, dependent: :purge_later
  has_many :books, dependent: :destroy
  has_many :memos, dependent: :destroy
  has_many :tags, class_name: "ActsAsTaggableOn::Tag", dependent: :destroy
  has_many :like_memos, dependent: :destroy
  has_many :liked_memos, through: :like_memos, source: :memo
  # Include default devise modules. Others available are:
  #  :timeoutable, :trackable
  devise :database_authenticatable, :registerable, :lockable,
        :recoverable, :rememberable, :validatable, :confirmable,
        :omniauthable, omniauth_providers: [ :line ]

  after_update :maybe_switch_to_email_login

  def line_login_only?
    auth_provider == "line"
  end

  def email_login?
    auth_provider == "email"
  end

  validates :name, length: { maximum: 50, message: ": 名前は50文字以内で入力してください" }

  # 例：Stripeの顧客IDとサブスクリプションIDを持っている前提
  # customer_id: string
  # subscription_id: string

  def bokrium_premium?
    true
    # return false if subscription_id.blank?

    # begin
    #   subscription = Stripe::Subscription.retrieve(subscription_id)
    #   subscription.status == "active"
    # rescue Stripe::InvalidRequestError
    #   false
    # end
  end

  private

  def maybe_switch_to_email_login
    return unless auth_provider == "line"

    email_changed = saved_change_to_email?
    password_changed = saved_change_to_encrypted_password?
    return unless email_changed || password_changed

    update_auth_provider_if_email_ready
    save if changed? # auth_provider が変わった場合のみ再保存
  end

  def update_auth_provider_if_email_ready
    return unless auth_provider == "line"

    email_valid = email.present? &&
                  !email.starts_with?("line_user_") &&
                  email.match?(URI::MailTo::EMAIL_REGEXP)

    password_valid = encrypted_password.present?

    email_confirmed = !devise_modules.include?(:confirmable) || confirmed?

    if email_valid && password_valid && email_confirmed
      self.auth_provider = "email"
    end
  end
end
