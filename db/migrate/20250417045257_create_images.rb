class CreateImages < ActiveRecord::Migration[8.0]
  def change
    create_table :images do |t|
      t.references :memo, null: false, foreign_key: true
      t.string :image_path

      t.timestamps
    end
  end
end
