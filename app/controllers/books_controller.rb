class BooksController < ApplicationController
  before_action :authenticate_user!, only: %i[ index create show edit update destroy ]
  before_action :set_book, only: %i[ edit update destroy ]
  before_action :set_book_with_associations, only: [ :show ]
  before_action :set_user_tags, only: %i[ show ]

  def index
    unless current_user.books.exists?
      redirect_to guest_books_path and return
    end
    @has_books = true

    presenter = BooksIndexPresenter.new(
      user: current_user,
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
    @spine_per_shelf     = presenter.spine_per_shelf
    @card_columns        = presenter.card_columns
    @detail_card_columns = presenter.detail_card_columns

    turbo_frame_request? ? render_chunk_for(@view_mode) : render(:index)
  end

  def show
    @memos = @book.memos.order(created_at: :desc)
    @new_memo = @book.memos.new(user_id: current_user.id)
    @user_tag = UserTag.new
  end

  def new
    @book = Book.new
  end

  def create
    @book = current_user.books.build(book_params)
    @book.save ? respond_success("本棚に『#{@book.title.truncate(TITLE_TRUNCATE_LIMIT)}』を追加しました。") : respond_failure(@book.errors.full_messages.to_sentence.presence || "追加に失敗しました。")
  end

  def edit
    respond_to do |format|
      format.turbo_stream { render partial: "bookshelf/b_note_edit_row", locals: { book: @book } }
      format.html
    end
  end

  def update
    if @book.update(book_params)
      flash[:info] = "『#{@book.title.truncate(TITLE_TRUNCATE_LIMIT)}』を更新しました。"
      redirect_to @book
    else
      flash.now[:danger] = "画像の保存に失敗しました：#{@book.errors.full_messages.join('、')}"
      render :edit
    end
  end

  def destroy
    @book.destroy
    flash[:info] = "『#{@book.title.truncate(TITLE_TRUNCATE_LIMIT)}』を削除しました。"

    if params[:force_html]
      redirect_to books_path, notice: flash[:info]
    else
      respond_to do |format|
        format.turbo_stream do
          flash.now[:info] = flash[:info]
          render turbo_stream: [
            turbo_stream.remove("book_row_#{@book.id}"),
            turbo_stream.append("flash", partial: "shared/flash")
          ]
        end
        format.html { redirect_to books_path, notice: flash[:info] }
      end
    end
  end

  def clear_filters
    %i[sort status memo_visibility tags view].each { |key| session.delete(key) }
    redirect_to books_path
  end

  private

  def render_chunk_for(view_mode)
    case view_mode
    when "shelf"
      render partial: "bookshelf/kino_chunk", locals: { books: @books, books_per_shelf: @books_per_shelf, pagy: @pagy }
    when "spine"
      render partial: "bookshelf/spine_chunk", locals: { books: @books, spine_per_shelf: @spine_per_shelf, pagy: @pagy }
    else
      render :index
    end
  end

  def set_book
    @book = current_user.books.find(params[:id])
  end

  def set_book_with_associations
    @book = current_user.books.includes(:user_tags, :images, book_cover_s3_attachment: :blob).find(params[:id])
  end

  def set_user_tags
    @user_tags = current_user.user_tags.order(:id)
  end

  def book_params
    params.require(:book).permit(:isbn, :title, :publisher, :page, :book_cover, :author, :price, :status, :book_cover_s3, :affiliate_url)
  end

  def respond_success(message, redirect_path = search_books_path)
    flash[:info] = message
    respond_to do |format|
      format.turbo_stream { flash.now[:info] = message }
      format.html { redirect_to redirect_path }
    end
  end

  def respond_failure(message, render_action = :new)
    flash.now[:danger] = message
    respond_to do |format|
      format.turbo_stream
      format.html { render render_action, status: :unprocessable_entity }
    end
  end
end
