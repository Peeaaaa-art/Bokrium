class AddAuthProviderToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :auth_provider, :string, default: "email", null: false
  end
end
