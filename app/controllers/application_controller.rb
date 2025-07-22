class ApplicationController < ActionController::Base
  include Pagy::Backend
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :guest_user, :mobile?, :books_index_path, :book_link_path

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

  def books_index_path(view: nil, page: nil, tag: nil, tags: nil, sort: nil, status: nil, memo_visibility: nil)
    params = {}
    params[:view] = view if view.present?
    params[:page] = page if page.present?
    params[:tag] = tag if tag.present?
    params[:tags] = tags if tags.present?
    params[:sort] = sort if sort.present?
    params[:status] = status if status.present?
    params[:memo_visibility] = memo_visibility if memo_visibility.present?

    if user_signed_in?
      if current_user.books.exists?
        books_path(params)
      else
        guest_books_path(params)
      end
    else
      guest_books_path(params)
    end
  end

  def book_link_path(book)
    return guest_starter_book_path(book) if @starter_book

    if user_signed_in?
      @has_books ? book_path(book) : guest_book_path(book)
    else
      guest_book_path(book)
    end
  end
end
