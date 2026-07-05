class ReadingBoardController < ApplicationController
  include ReadingBoardColumns

  VIEWS = %w[list kanban].freeze

  before_action :authenticate_user!

  def show
    @view = resolve_view

    if @view == "kanban"
      @kanban_columns = Book.statuses.keys.map { |status| kanban_column(status) }
    else
      @books = current_user.books
        .reading
        .with_attached_book_cover_s3
        .by_reading_deadline
    end
  end

  private

  # viewの選択はセッションに記憶する(次回も同じviewで開く)
  def resolve_view
    requested = params[:view].presence
    view = VIEWS.include?(requested) ? requested : session[:reading_board_view]
    view = VIEWS.first unless VIEWS.include?(view)
    session[:reading_board_view] = view
    view
  end
end
