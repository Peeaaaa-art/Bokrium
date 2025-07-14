class MemosController < ApplicationController
  include ActionView::RecordIdentifier
  before_action :authenticate_user!
  before_action :set_book
  before_action :set_memo, only: [ :edit, :update, :destroy ]

  def new
    @memo = @book.memos.new
  end

  def create
    @memo = current_user.memos.new(memo_params)
    @memo.book_id = params[:book_id]
    @book = @memo.book

    if @memo.save
      flash[:info] = "メモを保存しました。"
      redirect_to book_path(@memo.book)
    else
      flash[:danger] = "メモの保存に失敗しました。"
      render "books/show", status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    @memos = @book.memos.order(created_at: :asc)
    @memo = current_user.memos.find(params[:id])
    if @memo.update(memo_params)
      flash[:info] = "メモを保存しました。"
      redirect_to book_path(@memo.book)
    else
      flash[:danger] = "メモの保存に失敗しました。"
      render status: :unprocessable_entity
    end
  end

  def destroy
    @memo.destroy
    flash.now[:info] = "メモを削除しました。"
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(@memo)),
          turbo_stream.update("flash", partial: "shared/flash")
        ]
      end
      format.html { redirect_to book_path(@book), status: :see_other }
    end
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end

  def set_memo
    @memo = current_user.memos.find(params[:id])
  end

  def memo_params
    params.require(:memo).permit(:content, :visibility).tap do |prm|
    prm[:visibility] = Memo::VISIBILITY[prm[:visibility].to_sym] if prm[:visibility]
    end
  end
end
