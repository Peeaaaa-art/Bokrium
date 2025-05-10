class RenamePublishedToVisibilityInMemos < ActiveRecord::Migration[8.0]
  def change
    rename_column :memos, :published, :visibility
  end
end
