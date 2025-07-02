module Guest
  class BooksController < ApplicationController
    before_action :read_only
    before_action :set_guest_book, only: [ :show ]
    rescue_from ActiveRecord::RecordNotFound, with: :handle_guest_not_found
    CHUNKS_PER_PAGE = 7
    def index
      books = Rails.cache.fetch("guest_sample_books", expires_in: nil) do
        guest_user.books
          .includes(book_cover_s3_attachment: :blob)
          .order(created_at: :desc)
          .to_a
      end
      @no_books = true

      @filtered_tags = []
      @filtered_status = nil

      display = BooksDisplaySetting.new(session, params, {
        shelf: default_books_per_shelf,
        card: default_card_columns,
        detail_card: default_detail_card_columns,
        spine: default_spine_per_shelf
        }, mobile: mobile?)

      @view_mode       = display.view_mode
      @books_per_shelf = display.books_per_shelf
      @card_columns    = display.card_columns
      @detail_card_columns = display.detail_card_columns
      @spine_per_shelf = display.spine_per_shelf

      books_per_page = display.unit_per_page * CHUNKS_PER_PAGE
      @pagy, @books = pagy_array(books, limit: books_per_page)
    end

    def show
      @memos = @book.memos
      @new_memo = Memo.new(book_id: @book.id)
      @user_tags = []

      render "books/show"
    end

    private

    def set_guest_book
      @book = guest_user.books.find(params[:id])
    end

    def read_only
      @read_only = true
    end

    def handle_guest_not_found
      flash[:danger] = "この本はゲスト表示できません。"
      redirect_to root_path
    end
  end
end
