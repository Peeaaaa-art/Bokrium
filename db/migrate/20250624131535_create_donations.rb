class CreateDonations < ActiveRecord::Migration[8.0]
  def change
    create_table :donations do |t|
      t.references :user, foreign_key: true
      t.integer :amount, null: false
      t.string :currency, default: "jpy", null: false
      t.string :stripe_payment_intent_id
      t.string :stripe_checkout_session_id
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
  end
end
