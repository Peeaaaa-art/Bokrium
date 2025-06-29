class AddUserToBookTagAssignments < ActiveRecord::Migration[8.0]
  def change
    add_reference :book_tag_assignments, :user, null: false, foreign_key: true
  end
end
