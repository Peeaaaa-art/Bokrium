# app/services/line_notification_sender.rb
class LineNotificationSender
  def self.send_all
    User.joins(:line_user).find_each do |user|
      send_random_memo_to(user)
    end
  end

  def self.send_random_memo_to(user)
    return unless user&.line_user&.line_id.present?
    return if user.memos.empty?

    memo = user.memos.order("RANDOM()").first
    message = Line::Bot::V2::MessagingApi::TextMessage.new(
      text: "📚 今日のメモ:\n\n#{strip_tags(memo.content).truncate(100)}"
    )

    request = Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: user.line_user.line_id,
      messages: [message]
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