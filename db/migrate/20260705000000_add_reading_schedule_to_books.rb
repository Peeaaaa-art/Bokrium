class AddReadingScheduleToBooks < ActiveRecord::Migration[8.1]
  def change
    add_column :books, :target_finish_on, :date
    add_column :books, :current_page, :integer
  end
end
