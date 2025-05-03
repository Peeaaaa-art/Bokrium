class DropBookTagsAndTagsTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :book_tags
    drop_table :tags
  end
end
