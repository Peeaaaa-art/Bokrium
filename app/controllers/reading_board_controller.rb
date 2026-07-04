class ReadingBoardController < ApplicationController
  before_action :authenticate_user!

  def show
    @books = current_user.books
      .reading
      .with_attached_book_cover_s3
      .order(Arel.sql("target_finish_on ASC NULLS LAST"))
      .order(:created_at)
  end
end
