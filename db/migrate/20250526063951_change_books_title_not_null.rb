class ChangeBooksTitleNotNull < ActiveRecord::Migration[8.0]
  def change
    change_column_null :books, :title, false
  end
end
