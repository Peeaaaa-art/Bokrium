class BooksController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :edit, :update, :destroy ]
  before_action :set_book, only: [ :show, :edit, :update, :destroy ]
  before_action :authorize_book, only: [ :edit, :update, :destroy ]

  def index
    if user_signed_in?
      @books = current_user.books.order(created_at: :desc)
      if @books.empty?
        @books = sample_books
        @no_books = true
      end
    else
      @books = sample_books
      @not_logged_in = true
    end
  end

  def show
    # @others_memos = @book.memos.where(published: 1)
    if @book.user_id == current_user.id
      @memos = @book.memos.order(created_at: :desc)
      @memo = @memos.first || @book.memos.new(user_id: current_user.id)
      @new_memo = @book.memos.new(user_id: current_user.id)
    else
      @memos = []
      @memo = nil
      @new_memo = nil
    end

    @tags = @book.tags
  end

  def new
    @book = Book.new
  end

  def create
    @book = current_user.books.build(book_params)

    if @book.save
      if params[:tags].present?
        params[:tags].split(",").each do |tag_name|
          tag = Tag.find_or_create_by(name: tag_name.strip)
          @book.book_tags.create(tag_id: tag.id)
        end
      end

      flash.now[:success] = "My本棚に『#{@book.title.truncate(30)}』を追加しました"
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to books_path, notice: "My本棚に『#{@book.title.truncate(30)}』を追加しました" }
      end
    else
      flash.now[:danger] = "追加に失敗しました"
      respond_to do |format|
        format.turbo_stream
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @tags = @book.tags.pluck(:name).join(", ")
  end

  def update
    if params[:tags].present?
      tag_names = params[:tags].to_s.split(",").map(&:strip).reject(&:blank?)
      tags = tag_names.map { |name| Tag.find_or_create_by(name: name) }
      @book.tags = tags
    end

    if @book.update(book_params)
      redirect_to @book, notice: "書籍情報が更新されました"
    else
      render :edit
    end
  end

  def destroy
    @book.destroy
    redirect_to books_path, notice: "書籍が削除されました"
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
    [
      (1..15).map do |i|
        Book.new(title: "optimized#{i}.jpg")
      end
    ].flatten
  end
end
