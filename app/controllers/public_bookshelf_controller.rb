class PublicBookshelfController < ApplicationController
  def index
    @others_random_memo = Memo.random_public_memo
    @random_memos = Memo.random_nine_public(exclude_user: current_user)
    @view_mode = ""
  end

  def show
    @book = Book.find_by(id: params[:id])

    # if @book.nil? || @book.user_id == current_user&.id || @book.memos.publicly_listed.empty?
    #   redirect_to public_bookshelf_index_path, alert: "この本は表示できません。"
    #   return
    # end

    @memos = @book.memos.publicly_listed.order(created_at: :desc)
  end
end
