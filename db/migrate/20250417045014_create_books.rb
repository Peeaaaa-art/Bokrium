class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.string :isbn
      t.string :publisher
      t.integer :page
      t.string :book_cover

      t.timestamps
    end
  end
end
