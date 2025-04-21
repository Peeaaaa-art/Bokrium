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
    @memo = current_user.memos.new(memo_params)
    @memo.book_id = params[:book_id]

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

    if @memo.update(memo_params) # ← memo_paramsを使う
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
    params.require(:memo).permit(:content, :published).tap do |prm| # paramsの略
      # contentをJSON形式に変換（textキーでラップ）
      prm[:content] = { "text" => prm[:content] } if prm[:content]

      # enumキーをinteger値に変換（例: "you_can_see" → 1）
      prm[:published] = Memo.publisheds[prm[:published]] if prm[:published]
    end
  end
end
