class AddColorToTags < ActiveRecord::Migration[8.0]
  def change
    add_column :tags, :color, :string
  end
end
