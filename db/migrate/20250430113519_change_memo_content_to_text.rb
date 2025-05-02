class ChangeMemoContentToText < ActiveRecord::Migration[8.0]
  def up
    # jsonb → text に変換し、"text" キーの中身だけを保存
    change_column :memos, :content, :text, using: "content->>'text'"
  end

  def down
    # 巻き戻し時は空の jsonb に戻す（任意）
    change_column :memos, :content, :jsonb, default: {}, null: false
  end
end
