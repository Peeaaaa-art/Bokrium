class RenameCustomerIdToStripeCustomerIdInDonations < ActiveRecord::Migration[8.0]
  def change
    rename_column :donations, :customer_id, :stripe_customer_id
  end
end
