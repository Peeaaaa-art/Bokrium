class PublicBookshelfController < ApplicationController
  def index
    @view_mode = ""

    @pagy, @memos = pagy(Memo.publicly_listed_with_book_and_user(exclude_user: current_user), limit: 9)
  end

  def show
    @book = Book.find_by(id: params[:id])
    @memos = @book.memos.publicly_listed.order(created_at: :desc)
  end
end
