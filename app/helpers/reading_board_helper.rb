module ReadingBoardHelper
  # 読書スケジュールの状態バッジ
  def reading_schedule_badge(book)
    case book.reading_schedule_status
    when :overdue
      days = book.days_remaining.abs
      content_tag(:span, "#{days}日超過", class: "badge rounded-pill bg-danger")
    when :due_today
      content_tag(:span, "本日まで", class: "badge rounded-pill bg-warning text-dark")
    when :on_track
      content_tag(:span, "あと#{book.days_remaining}日", class: "badge rounded-pill bg-success")
    else # :no_target / :finished
      content_tag(:span, "目標日 未設定", class: "badge rounded-pill bg-secondary")
    end
  end

  # 必要ペースの説明テキスト(算出できないときは案内文)
  def reading_pace_text(book)
    remaining = book.pages_remaining
    pace = book.required_daily_pages

    if book.target_finish_on.nil?
      "目標日を決めると、1日に読むページ数の目安が出ます"
    elsif remaining.nil?
      "総ページ数と現在ページを入れると、必要ペースが出ます"
    elsif remaining.zero?
      "読了ページに到達しています 🎉"
    elsif book.reading_schedule_status == :overdue
      "残り#{remaining}ページ(期限超過)"
    else
      "残り#{remaining}ページ / #{book.days_remaining}日 → 1日#{pace}ページ"
    end
  end
end
