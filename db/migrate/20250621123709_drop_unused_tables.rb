class DropUnusedTables < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :comments, :users if foreign_key_exists?(:comments, :users)
    remove_foreign_key :comments, :memos if foreign_key_exists?(:comments, :memos)
    remove_foreign_key :line_notification_statuses, :line_notifications if foreign_key_exists?(:line_notification_statuses, :line_notifications)
    remove_foreign_key :line_notification_statuses, :line_users if foreign_key_exists?(:line_notification_statuses, :line_users)
    remove_foreign_key :line_notifications, :memos if foreign_key_exists?(:line_notifications, :memos)
    remove_foreign_key :line_users, :users if foreign_key_exists?(:line_users, :users)
    remove_foreign_key :search_terms, :users if foreign_key_exists?(:search_terms, :users)

    remove_foreign_key :solid_queue_blocked_executions, :solid_queue_jobs if foreign_key_exists?(:solid_queue_blocked_executions, :solid_queue_jobs)
    remove_foreign_key :solid_queue_claimed_executions, :solid_queue_jobs if foreign_key_exists?(:solid_queue_claimed_executions, :solid_queue_jobs)
    remove_foreign_key :solid_queue_failed_executions, :solid_queue_jobs if foreign_key_exists?(:solid_queue_failed_executions, :solid_queue_jobs)
    remove_foreign_key :solid_queue_ready_executions, :solid_queue_jobs if foreign_key_exists?(:solid_queue_ready_executions, :solid_queue_jobs)
    remove_foreign_key :solid_queue_recurring_executions, :solid_queue_jobs if foreign_key_exists?(:solid_queue_recurring_executions, :solid_queue_jobs)
    remove_foreign_key :solid_queue_scheduled_executions, :solid_queue_jobs if foreign_key_exists?(:solid_queue_scheduled_executions, :solid_queue_jobs)

    drop_table :search_terms, if_exists: true
    drop_table :line_notifications, if_exists: true
    drop_table :line_notification_statuses, if_exists: true
    drop_table :comments, if_exists: true
    drop_table :solid_queue_blocked_executions, if_exists: true
    drop_table :solid_queue_claimed_executions, if_exists: true
    drop_table :solid_queue_failed_executions, if_exists: true
    drop_table :solid_queue_jobs, if_exists: true
    drop_table :solid_queue_pauses, if_exists: true
    drop_table :solid_queue_processes, if_exists: true
    drop_table :solid_queue_ready_executions, if_exists: true
    drop_table :solid_queue_recurring_executions, if_exists: true
    drop_table :solid_queue_recurring_tasks, if_exists: true
    drop_table :solid_queue_scheduled_executions, if_exists: true
    drop_table :solid_queue_semaphores, if_exists: true
    drop_table :solid_cable_messages, if_exists: true
  end
end
