class PublicBookshelfController < ApplicationController
  def index
    @view_mode = ""

    @pagy, @memos = pagy(Memo.publicly_listed_with_book_and_user(exclude_user: current_user), limit: 9)
  end

  def show
    @memo = Memo
              .includes(:book, :user)
              .find_by!(public_token: params[:token])

    raise ActiveRecord::RecordNotFound unless @memo.shared?

    @book = @memo.book
    @user = @memo.user
  end
end
