module Guest
  class BooksController < ApplicationController
    before_action :read_only
    before_action :set_guest_book, only: [ :show ]
    rescue_from ActiveRecord::RecordNotFound, with: :handle_guest_not_found

    def index
      presenter = BooksIndexPresenter.new(
        user: guest_user,
        params: params,
        session: session,
        mobile: mobile?,
        user_agent: request.user_agent,
        pagy_context: self
      ).call

      @books               = presenter.books
      @pagy                = presenter.pagy
      @view_mode           = presenter.view_mode
      @books_per_shelf     = presenter.books_per_shelf
      @card_columns        = presenter.card_columns
      @detail_card_columns = presenter.detail_card_columns
      @spine_per_shelf     = presenter.spine_per_shelf

      @no_books = true

      if turbo_frame_request?
        case request.headers["Turbo-Frame"]
        when "next_books"
          render_chunk_for(@view_mode, turbo_frame_id: "next_books")
        when "books_frame"
          render :index
        else
          # fallback: safest default
          render :index
        end
      else
        render :index
      end
    end

    def show
      @memos     = @book.memos
      @new_memo  = Memo.new(book_id: @book.id)
      @user_tags = []
      render "books/show"
    end

    def clear_filters
      %i[sort status memo_visibility tags view].each { |key| session.delete(key) }
      redirect_to guest_books_path
    end

    private

    def render_chunk_for(view_mode, turbo_frame_id: "books_frame")
      case view_mode
      when "shelf"
        render partial: "bookshelf/kino_chunk",
              locals: { books: @books, books_per_shelf: @books_per_shelf, pagy: @pagy, turbo_frame_id: turbo_frame_id }
      when "spine"
        render partial: "bookshelf/spine_chunk",
              locals: { books: @books, spine_per_shelf: @spine_per_shelf, pagy: @pagy, turbo_frame_id: turbo_frame_id }
      else
        render :index
      end
    end

    def set_guest_book
      @book = guest_user.books
              .includes(:user_tags, { images: :image_s3_attachment }, :book_cover_s3_attachment)
              .find(params[:id])
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
