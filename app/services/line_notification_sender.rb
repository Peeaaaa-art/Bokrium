class LineNotificationSender
  def self.send_all
    User.joins(:line_user).merge(LineUser.where(notifications_enabled: true)).find_each do |user|
      send_random_memo_to(user)
    end
  end

  def self.send_random_memo_to(user)
    return unless user&.line_user&.line_id.present?
    return if user.memos.empty?

    memo = user.memos.order("RANDOM()").first
    book = memo.book
    app_host = ENV["APP_HOST"] || Rails.application.routes.default_url_options[:host] || "https://bokrium.com"
    book_url = Rails.application.routes.url_helpers.book_url(book, host: app_host)

    message_text = <<~TEXT
      📚 今日のあなたのメモ

      『#{book.title.presence || "無題の本"}』より：
      #{ActionView::Base.full_sanitizer.sanitize(memo.content.to_s).truncate(280)}

      ▼ メモの詳細を見る
      #{book_url}
    TEXT

    message = Line::Bot::V2::MessagingApi::TextMessage.new(text: message_text)

    request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: user.line_user.line_id,
      messages: [ message ]
    )

    client = Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: ENV.fetch("LINE_CHANNEL_TOKEN")
    )

    client.push_message(push_message_request: request)
  end

  def self.strip_tags(html)
    ActionView::Base.full_sanitizer.sanitize(html)
  end
end
