class ChangeDefaultForPublishedInMemos < ActiveRecord::Migration[8.0]
  def change
    change_column_default :memos, :published, from: nil, to: false
  end
end
