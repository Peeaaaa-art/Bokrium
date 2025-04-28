class BooksController < ApplicationController
  # before_action :authenticate_user!
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
    @memos = @book.memos.all if @book.user_id == current_user.id
    @new_memo = @book.memos.new(user_id: current_user.id)
    @memo = if current_user
      @book.memos.where(user_id: current_user.id).order(created_at: :desc).first ||
      @book.memos.new(user_id: current_user.id)
    end

    @tags = @book.tags
  end


  def new
    @book = Book.new
  end

  def scan_result
    book = RakutenWebService::Books::Book.search(isbn: params[:isbn]).first

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "scanned-books",
          partial: "books/card",
          locals: { book: book }
        )
      end
    end
  end

  def create
    @book = current_user.books.build(book_params)

    if params[:isbn_scan].present?
      # ISBNバーコードスキャン処理（OCR/API連携）
      book_info = fetch_book_info_from_apis(params[:isbn_scan])
      @book.assign_attributes(book_info) if book_info.present?
    end

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
    unless @book.user_id == current_user.id
      redirect_to books_path, alert: "アクセス権限がありません"
    end
  end

  def book_params
    params.require(:book).permit(:isbn, :title, :publisher, :page, :book_cover, :author, :price, :status, :book_cover_s3, :ima)
  end

  def sample_books
    [
      (1..15).map do |i|
        Book.new(title: "optimized#{i}.jpg")
      end
    ].flatten
  end
end
