class RemoveImagePathFromImages < ActiveRecord::Migration[8.0]
  def change
    remove_column :images, :image_path, :string
  end
end
