class RemoveStripeFieldsFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :stripe_customer_id, :string
    remove_column :users, :stripe_subscription_id, :string
    remove_column :users, :subscription_status, :string
    remove_column :users, :cancel_at_period_end, :boolean
    remove_column :users, :current_period_end, :datetime
  end
end
