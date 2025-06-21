class AddEmailNotificationEnabledToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :email_notification_enabled, :boolean, default: false, null: false
  end
end
