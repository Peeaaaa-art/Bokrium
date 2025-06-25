class CreateMonthlySupports < ActiveRecord::Migration[8.0]
  def change
    create_table :monthly_supports do |t|
      t.references :user, null: false, foreign_key: true
      t.string :stripe_customer_id
      t.string :stripe_subscription_id
      t.string :subscription_status
      t.boolean :cancel_at_period_end
      t.datetime :current_period_end

      t.timestamps
    end
  end
end
