# 読書戦略ボード(かんばんview)の列データ構築。ボード表示と、ステータス更新後の
# Turbo Stream応答で同じ列の中身を組み立てるための共有ロジック
module ReadingBoardColumns
  # 読了列は直近の一定数だけ表示する(冊数が増えても列が重くならないように)
  KANBAN_FINISHED_LIMIT = 50

  private

  def kanban_column(status)
    {
      status: status.to_s,
      books: kanban_column_books(status),
      total: kanban_total_count(status)
    }
  end

  # 手動並び替え済み(board_positionあり)が先、未設定は各列の自動順で後ろに続く
  def kanban_column_books(status)
    scope = current_user.books
      .with_attached_book_cover_s3
      .order(Arel.sql("board_position ASC NULLS LAST"))
    case status.to_s
    when "want_to_read"
      scope.want_to_read.order(created_at: :desc)
    when "reading"
      scope.reading.by_reading_deadline
    when "finished"
      scope.finished.order(updated_at: :desc).limit(KANBAN_FINISHED_LIMIT)
    else
      scope.none
    end
  end

  def kanban_total_count(status)
    current_user.books.where(status: status).count
  end
end
