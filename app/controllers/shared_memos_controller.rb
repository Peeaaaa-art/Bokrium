class SharedMemosController < ApplicationController
  def show
    @memo = Memo
              .includes(:book, :user)
              .find_by!(public_token: params[:token])

    raise ActiveRecord::RecordNotFound unless @memo.shared?

    @book = @memo.book
    @user = @memo.user
  end
end
