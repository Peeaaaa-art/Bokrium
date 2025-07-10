class Books::TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book, only: [ :toggle ]

  def toggle
    BookTagToggleService.new(book: @book, user: current_user, tag_id: params[:tag_id], flash: flash).call
    redirect_back fallback_location: @book
  end

  def filter
    render partial: "books/tag_filter", locals: {
      user_tags: current_user.user_tags.order(:id),
      filtered_tags: []
    }
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end
end
