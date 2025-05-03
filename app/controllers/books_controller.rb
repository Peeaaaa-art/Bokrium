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
    if @book.user_id == current_user.id
      @memos = @book.memos.order(created_at: :desc)
      @new_memo = @book.memos.new(user_id: current_user.id)
      @user_tags = ActsAsTaggableOn::Tag.where(user: current_user)
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

    # タグ追加
    if params[:tags].present?
      @book.tag_list = params[:tags].to_s.split(/\s+/).map(&:strip)
    end

    if @book.save
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
    @tags = @book.tag_list.join(" ")
  end

  def update
    if params[:tags].present?
      @book.tag_list = params[:tags].to_s.split(/\s+/).map(&:strip)
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

  def assign_tag
    @book = Book.find(params[:id])
    tag_name = params[:tag_name]
    @book.tag_list.add(tag_name)
    @book.save

    redirect_back fallback_location: book_path(@book), notice: "#{tag_name} をタグ付けしました"
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
end
