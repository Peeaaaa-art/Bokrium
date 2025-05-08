class PublicBookshelfController < ApplicationController
  def index
    @others_random_memo = Memo.random_published_memo
  end

  def show
  end
end
