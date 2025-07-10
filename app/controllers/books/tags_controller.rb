class Books::TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book, only: %i[toggle filter clear]

  def toggle
    BookTagToggleService.new(book: @book, user: current_user, tag_id: params[:tag_id], flash: flash).call
    redirect_back fallback_location: @book
  end

  def filter
    render partial: "books/tag_filter", locals: { filtered_tags: [] }
  end

  def clear
    %i[sort status memo_visibility tags].each { |key| session.delete(key) }
    redirect_to books_path
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end
end
