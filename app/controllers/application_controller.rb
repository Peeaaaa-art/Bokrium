class ApplicationController < ActionController::Base
  include Pagy::Method
  allow_browser versions: :modern
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters, if: :devise_controller?
  helper_method :guest_user, :mobile?, :books_index_path, :book_link_path

  rescue_from Regexp::TimeoutError, with: :handle_regexp_timeout

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

  def handle_regexp_timeout(exception)
    Rails.logger.warn(
      "Regexp timeout: #{exception.class} - #{exception.message} " \
      "request_id=#{request.request_id} " \
      "path=#{request.request_method} #{request.path} " \
      "controller=#{self.class.name} action=#{action_name}"
    )
    Rails.logger.warn("Regexp timeout backtrace:\n#{exception.backtrace.first(10).join("\n")}") if exception.backtrace

    respond_to do |format|
      format.json { render json: { error: "regexp_timeout" }, status: :bad_request }
      format.html { render file: Rails.root.join("public/400.html").to_s, layout: false, status: :bad_request }
      format.any { head :bad_request }
    end
  end
end
