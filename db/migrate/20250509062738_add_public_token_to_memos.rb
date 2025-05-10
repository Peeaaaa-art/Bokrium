class AddPublicTokenToMemos < ActiveRecord::Migration[8.0]
  def change
    add_column :memos, :public_token, :string
    add_index :memos, :public_token, unique: true
  end
end
