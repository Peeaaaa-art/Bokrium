class RemoveUnusedColumnsFromUsersAndMemos < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :introduction, :text
    remove_column :users, :avatar, :string
    remove_column :memos, :text_index, :tsvector
  end
end
