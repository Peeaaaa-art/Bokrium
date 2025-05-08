class PublicBookshelfController < ApplicationController
  def index
    @others_random_memo = Memo.random_1
    @random_memos = Memo.random_nine(exclude_user: current_user)
  end

  def show
  end
end
