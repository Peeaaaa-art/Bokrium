class AddUniqueIndexToBooksOnUserIdAndIsbn < ActiveRecord::Migration[8.0]
  def change
    add_index :books, [ :user_id, :isbn ],
    unique: true,
    where: "isbn IS NOT NULL",
    name: "index_books_on_user_id_and_isbn_unique_if_isbn"
  end
end
