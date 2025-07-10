class ApplicationController < ActionController::Base
  include Pagy::Backend
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :guest_user, :mobile?

  def guest_user
    guest_email = ENV["GUEST_USER_EMAIL"]
    @guest_user ||= User.find_by(email: guest_email)
  end

  TITLE_TRUNCATE_LIMIT = 40

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :avatar_s3 ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :avatar_s3 ])
  end

  private

  def browser
    @browser ||= Browser.new(request.user_agent)
  end

  def mobile?
    browser.device.mobile?
  end
end
