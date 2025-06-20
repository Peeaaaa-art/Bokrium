class EmailNotificationSender
  def self.send_all
    retries = 0

    begin
      User
        .where.not(email: nil)
        .where(email_notification_enabled: true)
        .find_each do |user|
        send_random_memo_to(user)
      end
    rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
      if (retries += 1) <= 3
        Rails.logger.warn("DB接続失敗、#{retries}回目のリトライ中: #{e.class} - #{e.message}")
        sleep 10
        retry
      else
        Rails.logger.error("メール通知失敗（DB未接続）: #{e.class} - #{e.message}")
        raise
      end
    end
  end

  def self.send_random_memo_to(user)
    return unless user&.email.present?
    return if user.memos.empty?

    memo = user.memos.order("RANDOM()").first
    MemoMailer.random_memo_email(user, memo).deliver_now
  end
end
