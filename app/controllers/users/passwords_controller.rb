# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  rate_limit to: 10, within: 3.minutes, only: :create

  skip_before_action :require_no_authentication, only: [ :send_reset_link, :trigger_reset, :edit, :update ]
  before_action :authenticate_user!, only: [ :send_reset_link, :trigger_reset ]

  def send_reset_link
    # パスワードリセットリンク送信用フォーム
  end

  def trigger_reset
    current_user.send_reset_password_instructions
    redirect_to mypage_path(current_user), notice: "パスワード変更用のメールを送信しました。"
  end
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  # def create
  #   super
  # end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  # def update
  #   super
  # end

  # protected

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
