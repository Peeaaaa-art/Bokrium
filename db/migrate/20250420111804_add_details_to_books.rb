class AddDetailsToBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :author, :string
    add_column :books, :price, :integer
    add_column :books, :status, :integer, default: 0, null: false
  end
end
