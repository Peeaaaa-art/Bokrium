class AddBoardPositionToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :board_position, :integer
  end
end
