class AddStartedOnToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :started_on, :date
  end
end
