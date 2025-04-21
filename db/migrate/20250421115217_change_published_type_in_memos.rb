class ChangePublishedTypeInMemos < ActiveRecord::Migration[8.0]
  def up
    # 1. 新しいカラムを追加
    add_column :memos, :new_published, :integer, default: 0, null: false

    # 2. 既存データの変換（true→1, false→0）
    Memo.reset_column_information
    Memo.find_each do |memo|
      memo.update!(new_published: memo.published ? 1 : 0)
    end

    # 3. 元のカラムを削除
    remove_column :memos, :published

    # 4. 新しいカラムをリネーム
    rename_column :memos, :new_published, :published
  end

  def down
    # ロールバック用
    add_column :memos, :old_published, :boolean, default: false, null: false

    Memo.reset_column_information
    Memo.find_each do |memo|
      memo.update!(old_published: memo.published == 1)
    end

    remove_column :memos, :published
    rename_column :memos, :old_published, :published
  end
end
