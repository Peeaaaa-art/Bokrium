class CreateLineNotificationStatuses < ActiveRecord::Migration[8.0]
  def change
    create_table :line_notification_statuses do |t|
      t.references :line_user, null: false, foreign_key: true
      t.references :line_notification, null: false, foreign_key: true
      t.string :status
      t.timestamp :sent_at

      t.timestamps
    end
  end
end
