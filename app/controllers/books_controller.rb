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
    # 書籍のメモ一覧を取得
    # @memos = @book.memos.where(published: true)
    @memos = @book.memos.all if @book.user_id == current_user.id

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
      # タグの処理
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
    # タグの処理（BookControllerで管理）
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
    params.require(:book).permit(:isbn, :title, :publisher, :page, :book_cover)
  end

  def sample_books
    # サンプル書籍データ（DBには保存しない）
    [
      Book.new(
        title: "リーダブルコード",
        isbn: "9784873115658",
        publisher: "オライリー・ジャパン",
        page: 260,
        book_cover: "optimized1.jpg"
      ),
      Book.new(
        title: "世界99",
        isbn: "9784087718799",
        publisher: "集英社",
        page: 432,
        book_cover: "optimized2.jpg"
      ),
      Book.new(
        title: "チューリングの大聖堂: コンピュータの創造とデジタル世界の到来",
        isbn: "9784152093592",
        publisher: "早川書房",
        page: 648,
        book_cover: "optimized3.jpg"
      ),
      (4..15).map do |i|
        Book.new(book_cover: "optimized#{i}.jpg")
      end
    ].flatten
  end
end
