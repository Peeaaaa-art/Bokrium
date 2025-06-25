class AddCustomerIdToDonations < ActiveRecord::Migration[8.0]
  def change
    add_column :donations, :customer_id, :string
  end
end
