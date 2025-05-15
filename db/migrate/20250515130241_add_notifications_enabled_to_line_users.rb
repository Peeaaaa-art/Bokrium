class AddNotificationsEnabledToLineUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :line_users, :notifications_enabled, :boolean, default: true, null: false
  end
end
