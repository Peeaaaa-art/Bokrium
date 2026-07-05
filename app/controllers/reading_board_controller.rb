class ReadingBoardController < ApplicationController
  include ReadingBoardColumns

  VIEWS = %w[list kanban roadmap].freeze

  # ロードマップの時間軸ウィンドウの上限(極端な開始日・目標日でグリッドが
  # 巨大化しないように、過去・未来それぞれをこの日数で打ち切る)
  ROADMAP_PAST_LIMIT = 30
  ROADMAP_FUTURE_LIMIT = 120

  before_action :authenticate_user!

  def show
    @view = resolve_view

    case @view
    when "kanban"
      @kanban_columns = Book.statuses.keys.map { |status| kanban_column(status) }
    when "roadmap"
      prepare_roadmap
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

  def prepare_roadmap
    # ロードマップは書影を描画しないため、添付のeager loadはしない
    reading = current_user.books
      .reading
      .by_reading_deadline
      .to_a

    @roadmap_books = reading.select(&:target_finish_on)
    @no_target_books = reading.reject(&:target_finish_on)

    today = Date.current
    starts = @roadmap_books.map { |book| [ book.started_on || today, book.target_finish_on ].min }
    targets = @roadmap_books.map(&:target_finish_on)

    @window_start = [ ([ today - 7 ] + starts).min, today - ROADMAP_PAST_LIMIT ].max
    @window_end = [ ([ today + 21 ] + targets).max, today + ROADMAP_FUTURE_LIMIT ].min
    @total_days = (@window_end - @window_start).to_i + 1
    @today_ratio = ((today - @window_start).to_f + 0.5) / @total_days
  end
end
