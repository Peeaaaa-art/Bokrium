# frozen_string_literal: true

# This migration comes from acts_as_taggable_on_engine (originally 3)
class AddTaggingsCounterCacheToTags < ActiveRecord::Migration[6.0]
  def self.up
    add_column :tags, :taggings_count, :integer, default: 0

    execute <<~SQL.squish
      UPDATE tags
      SET taggings_count = taggings_counts.count
      FROM (
        SELECT tag_id, COUNT(*) AS count
        FROM taggings
        GROUP BY tag_id
      ) AS taggings_counts
      WHERE tags.id = taggings_counts.tag_id
    SQL
  end

  def self.down
    remove_column :tags, :taggings_count
  end
end
