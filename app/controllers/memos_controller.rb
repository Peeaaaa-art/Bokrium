class MemosController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_book
  before_action :set_memo, only: [ :show, :edit, :update, :destroy ]

  def index
    @memos = @book.memos.where(user_id: current_user.id).order(created_at: :desc)
  end

  def show
    # @comments = @memo.comments.includes(:user).order(created_at: :desc)
  end

  def new
    @memo = @book.memos.new
  end

  def create
    @memo = current_user.memos.new(memo_params)
    @memo.book_id = params[:book_id]
    @memo.content = {
      text: params[:text],
      tags: params[:tags].to_s.split(",").map(&:strip)
    }
    if @memo.save
      redirect_to book_memos_path(@memo.book, @memo), notice: "メモを保存しました"
    else
      render :new
    end
  end

  def edit
  end


  def update
    @memo = Memo.find(params[:id])
    @book = @memo.book
  
    @memo.content = { text: params[:memo][:content] }
  
    if @memo.save
      redirect_to book_memo_path(@book, @memo), notice: "メモを更新しました"
    else
      render :edit
    end
  end
  


  def destroy
    @memo.destroy
    redirect_to book_memos_path(@book), notice: "メモを削除しました"
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
    params.require(:memo).permit(:published, :content, :text)
  end
end
