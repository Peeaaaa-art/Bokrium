class PublicBookshelfController < ApplicationController
  def index
    @others_random_memo = Memo.random_one
  end

  def show
  end
end
