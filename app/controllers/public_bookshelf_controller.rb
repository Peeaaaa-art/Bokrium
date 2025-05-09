class PublicBookshelfController < ApplicationController
  def index
    @others_random_memo = Memo.random_1
    @random_memos = Memo.random_nine(exclude_user: current_user)
  end

  def show
    @book = Book.find_by(id: params[:id])

    if @book.nil? || @book.user_id == current_user&.id || @book.memos.published_to_others.empty?
      redirect_to public_bookshelf_index_path, alert: "この本は表示できません。"
      return
    end

    @memos = @book.memos.published_to_others.order(created_at: :desc)
  end
end
