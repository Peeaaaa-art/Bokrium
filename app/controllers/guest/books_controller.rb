module Guest
  class BooksController < ApplicationController
    def show
      @book = Book.find_by(id: params[:id], user_id: guest_user.id)

      unless @book
        redirect_to root_path, alert: "この本はゲスト表示できません"
        return
      end

      @memos = @book.memos.order(created_at: :desc)
      @new_memo = Memo.new(book_id: @book.id)
      @user_tags = []
      @readonly = true

      render "books/show"
    end

    def index
      @books = guest_user.books.all
      @no_books = true

      @filtered_tags = []
      @filtered_status = nil

      session[:view_mode] = params[:view] if params[:view].present?
      @view_mode = session[:view_mode] || "shelf"


      @books_per_row = params[:slice]&.to_i.presence || 12

      respond_to do |format|
        format.html { render "books/index" }
        format.turbo_stream
      end
    end
  end
end
