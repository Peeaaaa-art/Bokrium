module Guest
  class StarterBooksController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :handle_guest_not_found
    CHUNKS_PER_PAGE = 14

    def index
      set_know_how_book
      # display = BooksDisplaySetting.new(session, params, {
      #   shelf: default_books_per_shelf,
      #   card: default_card_columns
      # })

      # @books_per_shelf = display.books_per_shelf
      @books_per_shelf = 5
    end

    def show
      set_know_how_book
      @book = @books.find(params[:id])
      @memos = @book.memos
      @new_memo = Memo.new(book_id: @book.id)
      @user_tags = []
      @starter_book = true

      render "books/show"
    end

    private

    def set_know_how_book
      isbn_list = %w[9781001001001]
      @books = guest_user.books.where(isbn: isbn_list)
    end

    def handle_guest_not_found
      flash[:danger] = "この本はゲスト表示できません"
      redirect_to root_path
    end
  end
end
