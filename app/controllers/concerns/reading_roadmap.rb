# ロードマップviewのデータ構築。ボード表示と、バードラッグ保存後の
# Turbo Stream応答(ロードマップ全体の差し替え)で共有する
module ReadingRoadmap
  # 時間軸ウィンドウの上限(極端な開始日・目標日でグリッドが巨大化しないように、
  # 過去・未来それぞれをこの日数で打ち切る)
  ROADMAP_PAST_LIMIT = 30
  ROADMAP_FUTURE_LIMIT = 120

  private

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
