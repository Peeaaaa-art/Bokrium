# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [ :create ]
  # before_action :configure_account_update_params, only: [:update]

  # GET /resource/sign_up
  # def new
  #   super
  # end

  # POST /resource
  def create
    # パスキー登録フラグをチェック
    if params[:user][:register_with_passkey] == "true"
      build_resource(sign_up_params.except(:password, :password_confirmation))
      resource.instance_variable_set(:@registering_with_passkey, true)
      resource.password = Devise.friendly_token[0, 20]  # ダミーパスワード生成

      if resource.save
        yield resource if block_given?
        if resource.active_for_authentication?
          set_flash_message! :notice, :signed_up
          sign_up(resource_name, resource)
          # パスキー登録へ誘導するフラグ
          session[:setup_passkey_after_confirmation] = true
          respond_with resource, location: after_sign_up_path_for(resource)
        else
          # メール確認待ち
          set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
          # パスキー登録へ誘導するフラグ
          session[:setup_passkey_after_confirmation] = true
          expire_data_after_sign_in!
          respond_with resource, location: after_inactive_sign_up_path_for(resource)
        end
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    else
      # 通常のパスワード登録
      super
    end
  end

  # GET /resource/edit
  # def edit
  #   super
  # end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # メール確認待ち（development のみ。Docker 等で letter_opener を開けないとき用）
  def confirmation_pending
    flash.discard(:notice)
    render :confirmation_pending, layout: "application"
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :avatar_s3, :register_with_passkey ])
  end

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.permit(:account_update, keys: [:attribute])
  # end
  def after_update_path_for(resource)
    mypage_path
  end

  # The path used after sign up.
  def after_sign_in_path_for(resource)
    stored_location_for(resource) || (
      resource.sign_in_count == 1 ? guest_starter_books_path : mypage_path
    )
  end

  def after_inactive_sign_up_path_for(resource)
    return "/users/confirmation_pending" if Rails.env.development?
    super(resource)
  end

  def update_resource(resource, params)
    if params[:password].present? || params[:password_confirmation].present?
      super
    else
      resource.update_without_password(params.except(:current_password))
    end
  end
end
