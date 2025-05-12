class BooksController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :edit, :update, :destroy ]
  before_action :set_book, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_book, only: [ :edit, :update, :destroy ]

  def index
    return @books = sample_books unless user_signed_in?

    books = current_user.books

    return @books = sample_books.tap { @no_books = true } unless books.exists?

    books = books.tagged_with(params[:tag], owned_by: current_user) if params[:tag].present?
    @filtered_tag = params[:tag] if params[:tag].present?

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
    @books = books
  end

  def show
    if current_user && @book.user_id == current_user.id
      @memos = @book.memos.order(created_at: :desc)
      @new_memo = @book.memos.new(user_id: current_user.id)
      @user_tags = ActsAsTaggableOn::Tag.where(user: current_user)
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

    if params[:tags].present?
      @book.tag_list = params[:tags].to_s.split(/\s+/).map(&:strip)
    end

    if @book.save
      set_tagger_for_all_taggings(@book)

      flash.now[:success] = "My本棚に『#{@book.title.truncate(30)}』を追加しました"
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to books_path, notice: "My本棚に『#{@book.title.truncate(30)}』を追加しました" }
      end
    else
      flash.now[:danger] = @book.errors.full_messages.to_sentence.presence || "追加に失敗しました"
      respond_to do |format|
        format.turbo_stream
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if params[:tags].present?
      @book.tag_list = params[:tags].to_s.split(/\s+/).map(&:strip)
    end

    if @book.update(book_params)
      set_tagger_for_all_taggings(@book)
      redirect_to @book, notice: "書籍情報が更新されました"
    else
      render :edit
    end
  end

  def destroy
    @book.destroy

    respond_to do |format|
      if request.referrer&.include?("/books/#{@book.id}")
        format.html { redirect_to books_path, notice: "書籍が削除されました" }
      else
        format.turbo_stream
        format.html { redirect_to books_path, notice: "書籍が削除されました" }
      end
    end
  end

  def assign_tag
    @book = Book.find(params[:id])
    tag_name = params[:tag_name]

    @book.tag_list.add(tag_name)

    if @book.save
      set_tagger_for_specific_tag(@book, tag_name)
      redirect_back fallback_location: book_path(@book), notice: "#{tag_name} をタグ付けしました"
    else
      redirect_back fallback_location: book_path(@book), alert: "タグの追加に失敗しました"
    end
  end

  def toggle_tag
    @book = current_user.books.find(params[:id])
    tag_name = params[:tag_name]

    if @book.tag_list.include?(tag_name)
      @book.tag_list.remove(tag_name)
    else
      @book.tag_list.add(tag_name)
    end

    if @book.save
      set_tagger_for_specific_tag(@book, tag_name)
    end

    redirect_back fallback_location: @book
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def authorize_book
    redirect_to books_path, alert: "アクセス権限がありません" unless @book.user_id == current_user.id
  end

  def book_params
    params.require(:book).permit(:isbn, :title, :publisher, :page, :book_cover, :author, :price, :status, :book_cover_s3)
  end

  def sample_books
    (1..15).map { |i| Book.new(title: "optimized#{i}.jpg") }
  end

  def set_tagger_for_all_taggings(book)
    book.taggings.update_all(tagger_id: current_user.id, tagger_type: "User")
  end

  def set_tagger_for_specific_tag(book, tag_name)
    tag = ActsAsTaggableOn::Tag.find_by(name: tag_name)
    return unless tag

    book.taggings.where(tag_id: tag.id).update_all(tagger_id: current_user.id, tagger_type: "User")
  end
end
