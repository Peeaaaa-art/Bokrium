class LineNotificationStatus < ApplicationRecord
  belongs_to :line_user
  belongs_to :line_notification
end
