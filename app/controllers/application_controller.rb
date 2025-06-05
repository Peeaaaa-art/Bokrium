class ApplicationController < ActionController::Base
  include Pagy::Backend
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :guest_user, :mobile?, :default_books_per_shelf, :default_card_columns


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

  def default_card_columns
    mobile? ? 4 : 12
  end

  def default_detail_card_columns
    mobile? ? 1 : 3
  end
end
