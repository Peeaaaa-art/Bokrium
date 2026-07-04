class CreateHandwrittenNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :handwritten_notes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.jsonb :data, null: false, default: {}
      t.string :title
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :handwritten_notes, [ :user_id, :book_id ]
  end
end
