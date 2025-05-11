class WelcomeController < ApplicationController
  def index
    if user_signed_in?
      memos = current_user.memos.includes(:book)
      @random_memo = memos.random_1
      @memo_exists = memos.exists?
    end
  end
end
