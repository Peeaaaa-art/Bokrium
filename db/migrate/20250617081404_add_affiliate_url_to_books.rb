class AddAffiliateUrlToBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :affiliate_url, :string
  end
end
