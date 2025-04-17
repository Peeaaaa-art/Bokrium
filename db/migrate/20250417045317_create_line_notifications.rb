class CreateLineNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :line_notifications do |t|
      t.references :memo, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.timestamp :schedule_at

      t.timestamps
    end
  end
end
