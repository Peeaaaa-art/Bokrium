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
      @read_only           = presenter.read_only
      @view_mode           = presenter.view_mode
      @books_per_shelf     = presenter.books_per_shelf
      @card_columns        = presenter.card_columns
      @detail_card_columns = presenter.detail_card_columns
      @spine_per_shelf     = presenter.spine_per_shelf

      @no_books = true

      turbo_frame_request? ? render_chunk_for(@view_mode) : render(:index)
    end

    def show
      @memos     = @book.memos
      @new_memo  = Memo.new(book_id: @book.id)
      @user_tags = []
      render "books/show"
    end

    private

    def render_chunk_for(view_mode)
      case view_mode
      when "shelf"
        render partial: "guest/bookshelf/kino_chunk", locals: { books: @books, books_per_shelf: @books_per_shelf, pagy: @pagy }
      when "spine"
        render partial: "guest/bookshelf/spine_chunk", locals: { books: @books, spine_per_shelf: @spine_per_shelf, pagy: @pagy }
      else
        render :index
      end
    end

    def set_guest_book
      @book = guest_user.books.find(params[:id])
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
