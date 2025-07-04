class CreateUserTags < ActiveRecord::Migration[8.0]
  def change
    create_table :user_tags do |t|
      t.string :name
      t.string :color
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
