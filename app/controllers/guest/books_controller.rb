module Guest
  class BooksController < ApplicationController
    CHUNKS_PER_PAGE = 14

    before_action :set_guest_book, only: [ :show ]
    rescue_from ActiveRecord::RecordNotFound, with: :handle_guest_not_found

    def index
      books = guest_user.books
                  .includes(book_cover_s3_attachment: :blob)
                  .order(created_at: :desc)
      @no_books = true

      @filtered_tags = []
      @filtered_status = nil

      display = BooksDisplaySetting.new(session, params, {
        shelf: default_books_per_shelf,
        card: default_card_columns
      })

      @view_mode       = display.view_mode
      @books_per_shelf = display.books_per_shelf
      @card_columns    = display.card_columns

      books_per_page = display.unit_per_page * CHUNKS_PER_PAGE
      @pagy, @books = pagy(books, limit: books_per_page)
    end

    def show
      @memos = @book.memos
      @new_memo = Memo.new(book_id: @book.id)
      @user_tags = []
      @readonly = true

      render "books/show"
    end

    def how_to_use_index
      @books = guest_user.books.where(isbn: "9784898111277")
      render "guest/books/how_to_use_index"
    end

    private

    def set_guest_book
      @book = guest_user.books.find(params[:id])
    end

    def handle_guest_not_found
      flash[:danger] = "この本はゲスト表示できません"
      redirect_to root_path
    end
  end
end
