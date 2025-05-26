module Guest
  class BooksController < ApplicationController
    def show
      @book = guest_user.books.find(params[:id])

      unless @book
        flash[:danger] = "この本はゲスト表示できません"
        redirect_to root_path
        return
      end

      @memos = @book.memos.order(created_at: :desc)
      @new_memo = Memo.new(book_id: @book.id)
      @user_tags = []
      @readonly = true

      render "books/show"
    end

    def index
      @books = guest_user.books
          .includes(book_cover_s3_attachment: :blob)
          .order(created_at: :desc)
      @no_books = true

      @filtered_tags = []
      @filtered_status = nil

      session[:view_mode] = params[:view] if params[:view].present?
      @view_mode = session[:view_mode] || "shelf"

      @books_per_shelf  = session[:shelf_per]&.to_i || default_books_per_shelf
      @card_columns   = session[:card_columns]&.to_i
    end
  end
end
