class RemoveTextIndexTriggerFromMemos < ActiveRecord::Migration[8.0]
  def change
    execute <<~SQL
      DROP TRIGGER IF EXISTS update_text_index ON memos;
      DROP FUNCTION IF EXISTS memos_text_index_trigger();
    SQL
  end
end
