class ChangeMemoIdToNullableInImages < ActiveRecord::Migration[8.0]
  def change
    change_column_null :images, :memo_id, true
  end
end
