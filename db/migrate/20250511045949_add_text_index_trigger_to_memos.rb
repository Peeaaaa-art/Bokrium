class AddTextIndexTriggerToMemos < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      CREATE FUNCTION memos_text_index_trigger() RETURNS trigger AS $$
      BEGIN
        NEW.text_index := to_tsvector('simple', coalesce(NEW.content, ''));
        RETURN NEW;
      END
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER update_text_index
      BEFORE INSERT OR UPDATE ON memos
      FOR EACH ROW EXECUTE FUNCTION memos_text_index_trigger();
    SQL
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS update_text_index ON memos;
      DROP FUNCTION IF EXISTS memos_text_index_trigger();
    SQL
  end
end
