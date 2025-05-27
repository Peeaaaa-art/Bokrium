class BooksController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :show, :edit, :update, :destroy ]
  before_action :set_book, only: [ :show, :edit, :update, :destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  CHUNKS_PER_PAGE = 5

  def index
    # books_controller.rb の index メソッドの冒頭に以下を追加
    Rails.logger.debug "✅ pagy method defined? #{ defined?(pagy) }"
    Rails.logger.debug "✅ pagy method defined? #{ method(:pagy) }"
    books = current_user.books

    unless books.exists?
      @books = guest_user.books
          .includes(book_cover_s3_attachment: :blob)
          .order(created_at: :desc)
      @no_books = true
      return
    end

    if params[:tags].present?
      tag_names = Array(params[:tags])
      books = books.tagged_with(tag_names, owned_by: current_user)
      @filtered_tags = tag_names
    end

    if params[:status].present? && Book.statuses.key?(params[:status])
      books = books.where(status: params[:status])
      @filtered_status = params[:status]
    end

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

    # 👇ここで念のためにデフォルトを補完（保険）
    unit_per_page ||= default_books_per_shelf

    sort_param = params[:sort]
    case sort_param
    when "oldest"
      books = books.order(created_at: :asc)
    when "title_asc"
      books = books.order(Arel.sql("title COLLATE \"ja-x-icu\" ASC"))
    when "author_asc"
      books = books.order(author: :asc)
    when "latest_memo"
      books = books
                .left_joins(:memos)
                .group("books.id")
                .order(Arel.sql("MAX(memos.updated_at) DESC NULLS LAST"))
    else
      books = books.order(created_at: :desc)
    end

    # Pagyでチャンク取得
    books = books.includes(book_cover_s3_attachment: :blob)
    books_per_page = unit_per_page * CHUNKS_PER_PAGE
    Rails.logger.debug "🔍 filtered books count: #{books.count}"
    Rails.logger.debug "🔍 SQL: #{books.to_sql}"
    @pagy, @books = pagy(books, limit: books_per_page)

    Rails.logger.debug "📦 unit_per_page: #{unit_per_page}"
    Rails.logger.debug "📚 books_per_page: #{books_per_page}"
    Rails.logger.debug "🧭 current page: #{params[:page] || '1'}"
    Rails.logger.debug "🧮 @books.size: #{@books.size}"
    Rails.logger.debug "🧮 @pagy.vars: #{@pagy.vars.inspect}"
  end

  def show
    if current_user && @book.user_id == current_user.id
      @memos = @book.memos.order(created_at: :desc)
      @new_memo = @book.memos.new(user_id: current_user.id)
      @user_tags = ActsAsTaggableOn::Tag.owned_by(current_user)
      @tag = ActsAsTaggableOn::Tag.new
    else
      @memos = []
      @memo = nil
      @new_memo = nil
    end
  end

  def new
    @book = Book.new
  end

  def create
    @book = current_user.books.build(book_params)

    if @book.save
      set_tagger_for_all_taggings(@book)

      success_message = "本棚に『#{@book.title.truncate(TITLE_TRUNCATE_LIMIT)}』を追加しました"

      respond_to do |format|
        format.turbo_stream do
          flash.now[:info] = success_message
        end
        format.html do
          flash[:info] = success_message
          redirect_to search_books_path
        end
      end

    else
      failure_message = @book.errors.full_messages.to_sentence.presence || "追加に失敗しました"

      respond_to do |format|
        format.turbo_stream do
        flash.now[:danger] = failure_message
      end
        format.html do
          flash.now[:danger] = failure_message
          render :new, status: :unprocessable_entity
        end
      end
    end
  end

  def edit; end

  def update
    if @book.update(book_params)
      set_tagger_for_all_taggings(@book)
      flash[:info] = "『#{@book.title.truncate(TITLE_TRUNCATE_LIMIT)}』を更新しました"
      redirect_to @book
    else
      render :edit
    end
  end

  def destroy
    @book.destroy

    success_message = "『#{@book.title.truncate(TITLE_TRUNCATE_LIMIT)}』を削除しました"

    respond_to do |format|
      if request.referrer&.include?("/books/#{@book.id}") # 詳細ページから削除した場合の処理
        flash[:info] = success_message
        format.html { redirect_to books_path }
      else                                                # それ以外（例：一覧ページなど）から削除した場合の処理
        flash[:info] = success_message
        format.html { redirect_to books_path }
      end
    end
  end

  def toggle_tag
    @book = current_user.books.find(params[:id])
    tag_name = params[:tag_name]

    tag = ActsAsTaggableOn::Tag.owned_by(current_user).find_by(name: tag_name)
    unless tag
      flash[:danger] = "タグが見つかりません"
      return redirect_back fallback_location: @book
    end

    tagging = @book.taggings.find_by(
      tag_id: tag.id,
      tagger_id: current_user.id,
      tagger_type: "User",
      context: "tags"
    )

    if tagging
      tagging.destroy
      flash[:info] = "『#{tag_name}』のタグを解除しました"
    else
      @book.tag_list.add(tag.name)
      @book.save
      flash[:info] = "『#{tag_name}』をタグ付けしました"
      set_tagger_for_specific_tag(@book, tag.name)
    end

    redirect_back fallback_location: @book
  end

  def tag_filter
    @user_tags = ActsAsTaggableOn::Tag.owned_by(current_user)
    render partial: "books/tag_filter", locals: { filtered_tags: [] }
  end

  private

  def set_book
    @book = if action_name == "show"
        current_user.books.includes(:tags, :memos, :images, book_cover_s3_attachment: :blob).find(params[:id])
    else
        current_user.books.find(params[:id])
    end
  end

  def book_params
    params.require(:book).permit(:isbn, :title, :publisher, :page, :book_cover, :author, :price, :status, :book_cover_s3)
  end

  def set_tagger_for_all_taggings(book)
    book.taggings.update_all(tagger_id: current_user.id, tagger_type: "User")
  end

  def set_tagger_for_specific_tag(book, tag_name)
    tag = ActsAsTaggableOn::Tag.owned_by(current_user).find_by(name: tag_name)
    return unless tag

    book.taggings.where(tag_id: tag.id).update_all(tagger_id: current_user.id, tagger_type: "User")
  end

  def handle_record_not_found
    redirect_to books_path
  end
end
