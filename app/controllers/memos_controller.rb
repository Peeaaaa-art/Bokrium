class MemosController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :authenticate_user!
  before_action :set_book
  before_action :set_memo, only: [ :show, :edit, :update, :destroy ]

  def index; end

  def show; end

  def new
    @memo = @book.memos.new
  end

  def create
    @memo = current_user.memos.new(memo_params)
    @memo.book_id = params[:book_id]
    @book = @memo.book
    # @memos = @book.memos.order(created_at: :asc)

    if @memo.save
      redirect_to book_path(@memo.book), notice: "メモを保存しました"
    else
      render "books/show", status: :unprocessable_entity
    end
  end

  def edit; end


  def update
    @memos = @book.memos.order(created_at: :asc)
    @memo = Memo.find(params[:id])
    if @memo.update(memo_params)
      redirect_to book_path(@memo.book), notice: "メモを保存しました"
    else
      render status: :unprocessable_entity
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
    unless @memo.user_id == current_user.id || @memo.shared?
      redirect_to book_memo_path(@book), alert: "アクセス権限がありません"
    end
  end

  def memo_params
    params.require(:memo).permit(:content, :visibility).tap do |prm|
    # memo_params
    prm[:visibility] = Memo::VISIBILITY[prm[:visibility].to_sym] if prm[:visibility]
    end
  end
end
