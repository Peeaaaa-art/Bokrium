class MemosController < ApplicationController
  include ActionView::RecordIdentifier
  # before_action :authenticate_user!
  before_action :set_book
  before_action :set_memo, only: [ :show, :edit, :update, :destroy ]

  def index
    @memos = @book.memos.where(user_id: current_user.id).order(created_at: :desc)
  end

  def show
    @book = Book.find(params[:id])
    @memos = @book.memos.where(user_id: current_user.id).order(created_at: :desc)
  end

  def new
    @memo = @book.memos.new
  end

  def create
    @memo = current_user.memos.new(memo_params)
    @memo.book_id = params[:book_id]

    if @memo.save
      redirect_to book_path(@memo.book), notice: "メモを保存しました"
    else
      render "books/show", status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @memo.update(memo_params)
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to book_path(@book), notice: "更新しました" }
      end
    else
      render turbo_stream: turbo_stream.replace(
        dom_id(@memo),
        partial: "memos/memo_item",
        locals: { memo: @memo, index: 0, memos: @book.memos, book: @book }
      ), status: :unprocessable_entity
    end
  end

  def destroy
    @memo.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(dom_id(@memo)) }
      format.html { redirect_to book_path(@book), notice: "メモを削除しました", status: :see_other }
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end

  def set_memo
    @memo = Memo.find(params[:id])
    unless @memo.user_id == current_user.id || @memo.published
      redirect_to book_memo_path(@book), alert: "アクセス権限がありません"
    end
  end

  def memo_params
    params.require(:memo).permit(:content, :published).tap do |prm|
      # contentをJSON形式に変換（textキーでラップ）
      prm[:content] = { "text" => prm[:content] } if prm[:content]

      # enumキーをinteger値に変換（例: "you_can_see" → 1）
      prm[:published] = Memo.publisheds[prm[:published]] if prm[:published]
    end
  end
end
