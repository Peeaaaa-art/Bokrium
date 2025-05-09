class SharedMemosController < ApplicationController
  def show
    @memo = Memo
              .includes(book: :user)
              .find_by!(public_token: params[:token])

    unless @memo.shared?
      raise ActiveRecord::RecordNotFound
    end

    @book = @memo.book
    @user = @memo.user
  end
end
