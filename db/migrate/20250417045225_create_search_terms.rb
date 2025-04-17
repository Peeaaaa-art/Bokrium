class CreateSearchTerms < ActiveRecord::Migration[8.0]
  def change
    create_table :search_terms do |t|
      t.references :user, null: false, foreign_key: true
      t.string :term
      t.integer :score

      t.timestamps
    end
  end
end
