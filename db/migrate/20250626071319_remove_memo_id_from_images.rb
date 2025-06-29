class RemoveMemoIdFromImages < ActiveRecord::Migration[8.0]
  def change
    remove_column :images, :memo_id, :bigint
  end
end
