class AddUserIdAndColorToTags < ActiveRecord::Migration[8.0]
  def change
    add_reference :tags, :user, null: false, foreign_key: true
    add_column :tags, :color, :string
  end
end
