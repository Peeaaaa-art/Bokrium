class FixTaggingsIndexWithTenant < ActiveRecord::Migration[8.0]
  def change
    remove_index :taggings, name: "taggings_idx"

    add_index :taggings,
      [ :tenant, :tag_id, :taggable_id, :taggable_type, :context, :tagger_id, :tagger_type ],
      unique: true,
      name: "taggings_idx"
  end
end
