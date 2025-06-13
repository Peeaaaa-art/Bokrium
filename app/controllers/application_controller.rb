class ApplicationController < ActionController::Base
  include Pagy::Backend
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :guest_user, :mobile?, :default_books_per_shelf, :default_card_columns, :default_spine_per_shelf


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

  def default_spine_per_shelf
    case
    when browser.device.mobile? then 7
    when browser.device.tablet? then 14
    else 21
    end
  end

  def default_card_columns
    mobile? ? 4 : 12
  end

  def default_detail_card_columns
    mobile? ? 1 : 6
  end


  def limit_error_stream(id:, message:)
    turbo_stream.replace(
      id,
      partial: "shared/limit_reached_message",
      locals: { dom_id: id, message: message }
    )
  end
end
