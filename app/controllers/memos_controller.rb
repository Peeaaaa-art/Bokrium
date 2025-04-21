class MemosController < ApplicationController
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
    @memo = current_user.memos.new
    @memo.book_id = params[:book_id]

    # content属性を適切に処理
    if params[:memo][:content].present?
      @memo.content = { "text" => params[:memo][:content] }
    end

    @memo.published = params[:memo][:published]

    if @memo.save
      redirect_to book_path(@memo.book), notice: "メモを保存しました"
    else
      # エラー処理
      render "books/show", status: :unprocessable_entity
    end
  end


  def edit
  end


  def update
    @memo = Memo.find(params[:id])
    @book = @memo.book

    # content属性を適切に処理
    if params[:memo][:content].present?
      @memo.content = { "text" => params[:memo][:content] }
    end

    if @memo.save
      redirect_to book_path(@book), notice: "メモを更新しました"
    else
      render :edit, status: :unprocessable_entity
    end
  end


  def destroy
    @memo.destroy
    redirect_to book_memos_path(@book), notice: "メモを削除しました", status: :see_other
  end


  private

  def set_book
    @book = Book.find(params[:book_id])
  end

  def set_memo
    @memo = Memo.find(params[:id])
    # 自分のメモか公開されているメモのみアクセス可能
    unless @memo.user_id == current_user.id || @memo.published
      redirect_to book_memos_path(@book), alert: "アクセス権限がありません"
    end
  end

  def memo_params
    params.require(:memo).permit(:published, :content)
  end
end
