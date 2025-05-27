module Guest
  class BooksController < ApplicationController
    CHUNKS_PER_PAGE = 14
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
      books = guest_user.books
          .includes(book_cover_s3_attachment: :blob)
          .order(created_at: :desc)
      @no_books = true

      @filtered_tags = []
      @filtered_status = nil

      session[:view_mode] = params[:view] if params[:view].present?
      @view_mode = session[:view_mode] || "shelf"

      if @view_mode == "shelf"
        session[:shelf_per] = params[:per] if params[:per].present?
        @books_per_shelf = session[:shelf_per]&.to_i || default_books_per_shelf
        unit_per_page = @books_per_shelf
      elsif @view_mode == "card"
        session[:card_columns] = params[:column] if params[:column].present?
        @card_columns = session[:card_columns]&.to_i || default_card_columns
        unit_per_page = @card_columns
      end

      # 念のためにデフォルトを補完（保険）
      unit_per_page ||= default_books_per_shelf
      @books_per_shelf ||= default_books_per_shelf

      @books_per_shelf  = session[:shelf_per]&.to_i || default_books_per_shelf
      @card_columns   = session[:card_columns]&.to_i

      books_per_page = unit_per_page * CHUNKS_PER_PAGE
      @pagy, @books = pagy(books, limit: books_per_page)
    end
  end
end
