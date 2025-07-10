# frozen_string_literal: true

require_relative "bookshelf_display_defaults"

class BooksIndexPresenter
  include BookshelfDisplayDefaults

  CHUNKS_PER_PAGE = 7

  attr_reader :books, :pagy, :read_only, :display,
              :books_per_shelf, :card_columns,
              :detail_card_columns, :spine_per_shelf,
              :view_mode

  def initialize(user:, params:, session:, mobile:, user_agent:)
    @user        = user
    @params      = params
    @session     = session
    @mobile      = mobile
    @user_agent  = user_agent
  end

  def call
    user_books = @user.books.includes(book_cover_s3_attachment: :blob)

    if user_books.empty?
      load_guest_books
    else
      load_user_books(user_books)
    end

    self
  end

  private

  def load_guest_books
    @books = Rails.cache.fetch("guest_sample_books") do
      guest_user.books.includes(book_cover_s3_attachment: :blob).order(created_at: :desc).to_a
    end

    @read_only = true
    @pagy = nil
    setup_display
  end

  def load_user_books(user_books)
    setup_display
    sync_filter_params(%w[sort status memo_visibility])

    filtered_books = BooksQuery.new(user_books, params: @params, current_user: @user).call
    per_page = @display.unit_per_page * CHUNKS_PER_PAGE

    total_count = filtered_books.unscope(:select, :group, :order).count(:all)

    @pagy = Pagy.new(
      count: total_count,
      page:  @params[:page],
      items: per_page
    )

    @books = filtered_books.offset(@pagy.offset).limit(@pagy.vars[:items])
    @read_only = false
  end

  def setup_display
    browser = Browser.new(@user_agent)

    @display = BookshelfLayoutConfig.new(@session, @params, {
      shelf:        default_books_per_shelf(browser),
      card:         default_card_columns(@mobile),
      detail_card:  default_detail_card_columns(@mobile),
      spine:        default_spine_per_shelf(browser)
    }, mobile: @mobile)

    @view_mode           = @display.view_mode
    @books_per_shelf     = @display.books_per_shelf
    @card_columns        = @display.card_columns
    @detail_card_columns = @display.detail_card_columns
    @spine_per_shelf     = @display.spine_per_shelf
  end

  def sync_filter_params(keys)
    keys.each do |key|
      if @params.key?(key)
        @params[key].present? ? @session[key] = @params[key] : @session.delete(key)
      elsif @session[key].present?
        @params[key] = @session[key]
      end
    end
  end
end
