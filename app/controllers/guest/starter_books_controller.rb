module Guest
  class StarterBooksController < ApplicationController
    rescue_from ActiveRecord::RecordNotFound, with: :handle_guest_not_found

    def index
      return if handle_root_callbacks

      set_starter_books
    end

    def random_memo
      redirect_to root_path and return unless user_signed_in?

      set_random_memo
    end

    def show
      unless set_starter_books
        flash[:alert] = "ゲスト表示の準備ができていません。"
        redirect_to root_path and return
      end

      @book = @books.find(params[:id])
      @memos = @book.memos
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

    def handle_root_callbacks
      if params[:session_id].present?
        flash[:notice] = "Bokriumマンスリーサポートにご参加いただき、ありがとうございます。今後の運営の励みとなります。"
        redirect_to donations_thank_you_path
        true
      elsif params[:canceled]
        flash.now[:alert] = "ご登録はキャンセルされましたが、Bokriumにご関心をお寄せいただき、ありがとうございました。"
        false
      elsif params[:donation] == "success"
        flash[:notice] = "ご支援いただき、誠にありがとうございます！"
        session[:recent_donation] = true
        redirect_to donations_thank_you_path
        true
      elsif params[:donation] == "cancelled"
        flash.now[:alert] = "寄付はキャンセルされました。"
        false
      else
        false
      end
    end

    def set_random_memo
      return unless user_signed_in?

      memos = current_user.memos.includes(:book)
      @random_memo = memos.random_1
    end

    def set_starter_books
      @starter_book = true

      unless guest_user
        @books = Book.none
        return false
      end

      isbn_list = %w[9781001001001]
      @books = guest_user.books.where(isbn: isbn_list)

      true
    end

    def lazy_render(name, with_books: false, extra: {})
      if with_books && !set_starter_books
        render plain: "", status: :ok and return
      end

      render partial: "guest/starter_books/#{name}", locals: extra.merge(with_books ? { books: @books } : {})
    end

    def handle_guest_not_found
      flash[:danger] = "この本はゲスト表示できません。"
      redirect_to root_path
    end
  end
end
