class AddIndexesForOptimization < ActiveRecord::Migration[8.0]
  def up
    add_index :memos, :visibility unless index_exists?(:memos, :visibility)

    add_index :line_users, :line_id, unique: true unless index_exists?(:line_users, :line_id, unique: true)

    if index_exists?(:tags, :name, unique: true)
      remove_index :tags, :name
    end
    add_index :tags, [ :user_id, :name ], unique: true unless index_exists?(:tags, [ :user_id, :name ], unique: true)

    add_index :books, :author unless index_exists?(:books, :author)
  end

  def down
    remove_index :memos, :visibility if index_exists?(:memos, :visibility)

    remove_index :line_users, :line_id if index_exists?(:line_users, :line_id)

    if index_exists?(:tags, [ :user_id, :name ], unique: true)
      remove_index :tags, column: [ :user_id, :name ]
    end
    add_index :tags, :name, unique: true unless index_exists?(:tags, :name, unique: true)

    remove_index :books, :author if index_exists?(:books, :author)
  end
end
