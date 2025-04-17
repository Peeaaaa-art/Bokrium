class CreateLineUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :line_users do |t|
      t.references :user, null: false, foreign_key: true
      t.string :line_id
      t.string :line_name

      t.timestamps
    end
  end
end
