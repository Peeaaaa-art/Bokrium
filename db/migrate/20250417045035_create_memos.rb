class CreateMemos < ActiveRecord::Migration[8.0]
  def change
    create_table :memos do |t|
      t.references :user, null: false, foreign_key: true
      t.references :book, null: false, foreign_key: true
      t.jsonb :content
      t.tsvector :text_index
      t.boolean :published

      t.timestamps
    end
  end
end
