class AddCancelAtToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :cancel_at_period_end, :boolean
    add_column :users, :current_period_end, :datetime
  end
end
