module Guest
  class StarterBooksController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :handle_guest_not_found

    def index
      set_starter_books
    end

    def show
      set_starter_books
      @book = @books.find(params[:id])
      @memos = @book.memos.includes(:user)
      @new_memo = Memo.new(book_id: @book.id)
      @user_tags = []

      render "books/show"
    end

    def barcode_section
      lazy_render("barcode_section")
    end

    def bookshelf_section
      lazy_render("bookshelf_section")
    end

    def five_layouts
      lazy_render("five_layouts", extra: { mobile: mobile? })
    end

    def memo_section
      lazy_render("memo_section", with_books: true)
    end

    def public_section
      lazy_render("public_section")
    end

    def guidebook_section
      lazy_render("guidebook_section", with_books: true)
    end

    private

    def set_starter_books
      isbn_list = %w[9781001001001]
      @books = guest_user.books.where(isbn: isbn_list)

      @starter_book = true
    end

    def lazy_render(name, with_books: false, extra: {})
      set_starter_books if with_books
      render partial: "guest/starter_books/#{name}", locals: extra.merge(with_books ? { books: @books } : {})
    end

    def handle_guest_not_found
      flash[:danger] = "この本はゲスト表示できません。"
      redirect_to root_path
    end
  end
end
