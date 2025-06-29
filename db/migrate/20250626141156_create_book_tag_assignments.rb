class CreateBookTagAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :book_tag_assignments do |t|
      t.references :book, null: false, foreign_key: true
      t.references :user_tag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
