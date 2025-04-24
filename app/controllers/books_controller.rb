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

    # フォーム表示用の@memoを設定（最新のメモまたは新規メモ）
    @memo = if current_user
      # 現在のユーザーのこの本に関する最新のメモを取得
      @book.memos.where(user_id: current_user.id).order(created_at: :desc).first ||
      # メモがなければ新規メモオブジェクトを作成
      @book.memos.new(user_id: current_user.id)
    end

    @tags = @book.tags
  end


  def new
    @book = Book.new
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

      redirect_to @book, notice: "書籍が正常に登録されました"
    else
      render :new
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

  def add_memo_form
    @book = Book.find(params[:id])
    @memo = @book.memos.new
    respond_to do |format|
      format.turbo_stream # 自動的にadd_memo_form.turbo_stream.erbを参照
    end
  end

  # def search_by_isbn
  #   isbn = paramas[:isbn]
  #   @books = RakutenWebService::Books::Book.search(isbn: isbn)

  #   if @books.any?
  #     @book_data = @books.first
  #   else
  #     flash[:alert] = "該当する書籍が見つかりませんでした"
  #   end
  # end
  def search_by_isbn
    if params[:isbn].present?
      results = RakutenWebService::Books::Book.search(isbn: params[:isbn])
      @book_data = results.first if results.any?
    end
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
    params.require(:book).permit(:isbn, :title, :publisher, :page, :book_cover, :author, :price, :status)
  end

  def sample_books
    [
      (1..15).map do |i|
        Book.new(title: "optimized#{i}.jpg")
      end
    ].flatten
  end
end
