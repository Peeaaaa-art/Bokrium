# frozen_string_literal: true

require_relative "bookshelf_display_defaults"

class BooksIndexPresenter
  include BookshelfDisplayDefaults

  CHUNKS_PER_PAGE = 4

  attr_reader :books, :pagy, :read_only, :display,
              :books_per_shelf, :card_columns,
              :detail_card_columns, :spine_per_shelf,
              :view_mode

  def initialize(user:, params:, session:, mobile:, user_agent:, pagy_context: nil)
    @user        = user
    @params      = params
    @session     = session
    @mobile      = mobile
    @user_agent  = user_agent
    @pagy_context = pagy_context
  end

  def call
    setup_display
    user_books =
                case @view_mode
                when "b_note"
                  @user.books.select(:id, :title, :author, :publisher)
                else
                  @user.books.includes(:book_cover_s3_attachment)
                end

    load_user_books(user_books)
    self
  end

  private

  def load_user_books(user_books)
    sync_filter_params(%w[sort status memo_visibility])

    filtered_books = BooksQuery.new(user_books, params: @params, current_user: @user).call

    per_page = (@display.unit_per_page * CHUNKS_PER_PAGE).to_i

    if @pagy_context.present?
      @pagy, @books = @pagy_context.send(:pagy, filtered_books, limit: per_page)
    else
      @books = filtered_books.limit(per_page)
      @pagy  = nil
    end

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
