class BooksController < ApplicationController
  before_action :authenticate_user!, only: [ :index, :create, :show, :edit, :update, :destroy ]
  before_action :set_book, only: [ :edit, :update, :update_row, :destroy, :toggle_tag ]
  before_action :set_book_with_associations, only: [ :show ]
  before_action :set_user_tags, only: [ :show, :tag_filter ]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  CHUNKS_PER_PAGE = 7

  def index
    @has_books = Book.exists?(user_id: current_user.id)
    books = current_user.books.includes(book_cover_s3_attachment: :blob)

    unless books&.exists?
        @books = Rails.cache.fetch("guest_sample_books", expires_in: nil) do
        guest_user.books
          .includes(book_cover_s3_attachment: :blob)
          .order(created_at: :desc)
          .to_a
      end
      return
    end

    display = BooksDisplaySetting.new(session, params, {
      shelf: default_books_per_shelf,
      card: default_card_columns,
      detail_card: default_detail_card_columns,
      spine: default_spine_per_shelf
    }, mobile: mobile?)

    @view_mode = display.view_mode
    @books_per_shelf = display.books_per_shelf
    @card_columns = display.card_columns
    @detail_card_columns = display.detail_card_columns
    @spine_per_shelf = display.spine_per_shelf

    %w[sort status memo_visibility].each do |key|
      if params.key?(key)
        if params[key].present?
          session[key] = params[key]
        else
          session.delete(key)
        end
      elsif session[key].present?
        params[key] = session[key]
      end
    end

    books = BooksQuery.new(books, params: params, current_user: current_user).call

    books_per_page = display.unit_per_page * CHUNKS_PER_PAGE
    @pagy, @books = pagy(books, limit: books_per_page)

    if turbo_frame_request?
      case @view_mode
      when "shelf"
        render partial: "bookshelf/kino_chunk", locals: {
          books: @books,
          books_per_shelf: @books_per_shelf,
          pagy: @pagy
        }, layout: false
      when "spine"
        render partial: "bookshelf/spine_chunk", locals: {
          books: @books,
          spine_per_shelf: @spine_per_shelf,
          pagy: @pagy
        }, layout: false
      else
        render :index
      end
    else
      render :index
    end
  end

  def show
    @memos = @book.memos.order(created_at: :desc)
    @new_memo = @book.memos.new(user_id: current_user.id)
    @tag = ActsAsTaggableOn::Tag.new
  end

  def new
    @book = Book.new
  end

  def create
    @book = current_user.books.build(book_params)

    if @book.save
      respond_success("本棚に『#{@book.title.truncate(TITLE_TRUNCATE_LIMIT)}』を追加しました")
    else
      error_msg = @book.errors.full_messages.to_sentence

      if @book.errors.details[:base].any? { |e| e[:error] == :limit_exceeded }
        render turbo_stream: limit_error_stream(id: "book_limit_error", message: error_msg)
      else
        respond_failure(@book.errors.full_messages.to_sentence.presence || "追加に失敗しました")
      end
    end
  end

  def edit
    @book = current_user.books.find(params[:id])

    respond_to do |format|
      format.turbo_stream do
        render partial: "bookshelf/b_note_edit_row", locals: { book: @book }
      end

      format.html
    end
  end

  def edit_row
    @book = current_user.books.find(params[:id])
    render partial: "bookshelf/b_note_edit_row", locals: { book: @book }
  end

  def row
    @book = current_user.books.find(params[:id])
    render partial: "bookshelf/b_note_row", locals: { book: @book }
  end

  def update
    if @book.update(book_params)
      flash[:info] = "『#{@book.title.truncate(TITLE_TRUNCATE_LIMIT)}』を更新しました"
      redirect_to @book
    else
      error_messages = @book.errors.full_messages.join("、")
      flash.now[:danger] = "画像の保存に失敗しました：#{error_messages}"
      render :edit
    end
  end

  def update_row
    @book = current_user.books.find(params[:id])
    index = params[:index].to_i

    if @book.update(book_params)
      flash.now[:row_update_success] = "『#{@book.title.truncate(20)}』を更新しました"
      render partial: "bookshelf/b_note_row", formats: :html, locals: { book: @book, index: index }
    else
      render partial: "bookshelf/b_note_edit_row", formats: :html, locals: { book: @book, index: index }
    end
  end
  def destroy
    @book.destroy
    flash[:info] = "『#{@book.title.truncate(TITLE_TRUNCATE_LIMIT)}』を削除しました"

    if params[:force_html]
      redirect_to books_path, notice: flash[:info]
      return
    end

    respond_to do |format|
      format.turbo_stream do
        flash.now[:info] = flash[:info]
        render turbo_stream: [
          turbo_stream.remove("book_row_#{@book.id}"),
          turbo_stream.append("flash", partial: "shared/flash")
        ]
      end
      format.html do
        redirect_to books_path, notice: flash[:info]
      end
    end
  end

  def toggle_tag
    Tagging::BookTagToggleService.new(
      book: @book,
      user: current_user,
      tag_name: params[:tag_name],
      flash: flash
    ).call

    redirect_back fallback_location: @book
  end

  def tag_filter
    render partial: "books/tag_filter", locals: { filtered_tags: [] }
  end

  def clear_filters
    %i[sort status memo_visibility tags].each { |key| session.delete(key) }
    redirect_to books_path
  end

  def autocomplete
    return render json: [] unless user_signed_in?

    term = params[:term].to_s.strip
    return render json: [] if term.blank?

    results = current_user.books
                          .where("title ILIKE :term OR author ILIKE :term", term: "%#{term}%")
                          .select(:title, :author)
                          .distinct
                          .limit(10)
                          .map do |book|
                            {
                              value: book.title,
                              label: "#{book.title}（#{book.author.presence || '著者不明'}）"
                            }
                          end

    render json: results
  end

  private

  def set_book
    @book = current_user.books.find(params[:id])
  end

  def set_book_with_associations
    @book = current_user.books
              .includes(:tags, :memos, :images, book_cover_s3_attachment: :blob)
              .find(params[:id])
  end

  def set_user_tags
    @user_tags = ActsAsTaggableOn::Tag.owned_by(current_user).order(:id)
  end

  def book_params
    params.require(:book).permit(:isbn, :title, :publisher, :page, :book_cover, :author, :price, :status, :book_cover_s3)
  end

  def respond_success(message)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:info] = message
      end
      format.html do
        flash[:info] = message
        redirect_to search_books_path
      end
    end
  end

  def respond_failure(message)
    respond_to do |format|
      format.turbo_stream do
        flash.now[:danger] = message
      end
      format.html do
        flash.now[:danger] = message
        render :new, status: :unprocessable_entity
      end
    end
  end

  def handle_record_not_found
    redirect_to books_path
  end
end
