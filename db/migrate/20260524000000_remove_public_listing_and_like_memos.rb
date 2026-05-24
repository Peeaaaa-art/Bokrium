class RemovePublicListingAndLikeMemos < ActiveRecord::Migration[8.1]
  def up
    # Former public_site memos become link-only shares.
    execute <<~SQL.squish
      UPDATE memos
      SET visibility = 1
      WHERE visibility = 2
    SQL

    drop_table :like_memos, if_exists: true
  end

  def down
    create_table :like_memos do |t|
      t.references :user, null: false, foreign_key: true
      t.references :memo, null: false, foreign_key: true
      t.timestamps
    end
  end
end
