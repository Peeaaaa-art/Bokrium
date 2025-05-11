class AddTrigramIndexToMemos < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      CREATE EXTENSION IF NOT EXISTS pg_trgm;
      CREATE INDEX index_memos_on_content_trgm
      ON memos
      USING gin (content gin_trgm_ops);
    SQL
  end

  def down
    execute <<-SQL
      DROP INDEX IF EXISTS index_memos_on_content_trgm;
    SQL
  end
end
