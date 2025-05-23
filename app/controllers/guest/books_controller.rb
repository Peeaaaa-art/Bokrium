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

      browser = Browser.new(request.user_agent)
      device_type = browser.device

      default = case
      when device_type.mobile? then 5
      when device_type.tablet? then 8
      else 10
      end

      @books_per_row = params[:per].to_i.positive? ? params[:per].to_i : default
      @mobile = device_type.mobile?
    end
  end
end
