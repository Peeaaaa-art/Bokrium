module Guest
  class StarterBooksController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :handle_guest_not_found

    def index
      set_starter_books
    end

    def show
      set_starter_books
      @book = @books.find(params[:id])
      @memos = @book.memos
      @new_memo = Memo.new(book_id: @book.id)
      @user_tags = []

      render "books/show"
    end

    def five_layouts
      render partial: "guest/starter_books/five_layouts"
    end

    def barcode_section
      render partial: "guest/starter_books/barcode_section"
    end

    def bookshelf_section
      render partial: "guest/starter_books/bookshelf_section"
    end

    def memo_section
      set_starter_books
      render partial: "guest/starter_books/memo_section", locals: { books: @books }
    end

    private

    def set_starter_books
      isbn_list = %w[9781001001001]
      @books = guest_user.books.where(isbn: isbn_list)

      @starter_book = true
    end

    def handle_guest_not_found
      flash[:danger] = "この本はゲスト表示できません"
      redirect_to root_path
    end
  end
end
