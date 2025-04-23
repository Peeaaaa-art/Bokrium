class AddBookIdToImages < ActiveRecord::Migration[8.0]
  def change
    add_reference :images, :book, null: false, foreign_key: true
  end
end
