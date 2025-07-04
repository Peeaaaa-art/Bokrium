class AddLockableToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :failed_attempts, :integer
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime
  end
end
