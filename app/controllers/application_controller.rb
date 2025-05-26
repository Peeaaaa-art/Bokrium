class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :guest_user
  helper_method :mobile?
  helper_method :default_books_per_shelf

  def guest_user
    guest_email = ENV["GUEST_USER_EMAIL"]
    @guest_user ||= User.find_by(email: guest_email)
  end

  TITLE_TRUNCATE_LIMIT = 40

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name, :introduction, :avatar_s3 ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name, :introduction, :avatar_s3 ])
  end

  private

  def browser
    @browser ||= Browser.new(request.user_agent)
  end

  def mobile?
    browser.device.mobile?
  end

  def default_books_per_shelf
    case
    when browser.device.mobile? then 5
    when browser.device.tablet? then 8
    else 10
    end
  end
end
