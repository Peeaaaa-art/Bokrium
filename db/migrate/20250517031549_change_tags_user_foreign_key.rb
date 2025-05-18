class ChangeTagsUserForeignKey < ActiveRecord::Migration[8.0]
  def change
      remove_foreign_key :tags, :users

      add_foreign_key :tags, :users, on_delete: :cascade
  end
end
