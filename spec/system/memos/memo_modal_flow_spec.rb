# frozen_string_literal: true

require "rails_helper"

RSpec.describe "メモモーダル（書籍詳細→メモクリック→編集→保存 / もっと書く→新規作成→保存）", type: :system do
  let(:user) { create(:user) }
  let(:book) { create(:book, user: user) }
  let(:memo) { create(:memo, book: book, user: user, content: "<p>既存のメモ</p>") }
  let(:unique_suffix) { SecureRandom.hex(4) }
  let(:appended_text) { " E2E_#{unique_suffix}" }

  before do
    driven_by :selenium_chrome_headless
    sign_in user
  end

  context "既存メモの編集" do
    before { memo }

    it "書籍詳細でメモをクリックしてモーダルを開き、文章を追記して保存するとDBに反映される" do
      visit book_path(book)

      # メモカードをクリック（ドロップダウン等を避けて本文エリアをクリック）
      expect(page).to have_selector("[id='memo_#{memo.id}']", wait: 10)
      find("[id='memo_#{memo.id}'] .memo-body").click

      # モーダルが開くまで待機
      expect(page).to have_selector("#memoEditModal.show", wait: 10)

      # モーダル内の編集エリア（#rich-editor-root 内の ProseMirror に限定し、複数なら先頭を採用）
      editor = find("#memoEditModal #rich-editor-root .ProseMirror[contenteditable='true']", wait: 10, match: :first)
      editor.click
      editor.send_keys(appended_text)

      # 保存ボタンをクリック（モーダル内に限定）
      find("#memoEditModal button[title='保存']").click

      # リダイレクトで書籍詳細に戻るまで待機
      expect(page).to(have_current_path(book_path(book), wait: 10), -> { "current: #{page.current_path}" })
      expect(page).not_to have_selector("#memoEditModal.show", wait: 5)

      # DB に保存されていることを確認
      expect(memo.reload.content).to include(unique_suffix)
    end
  end

  context "新規メモ作成" do
    it "「もっと書く」からメモモーダルを開き、入力して保存するとDBに1件増えcontentに文字列が含まれる" do
      visit book_path(book)

      # 「もっと書く」ボタンをクリックしてモーダルを開く
      expect(page).to have_button("もっと書く", wait: 10)
      click_on "もっと書く"

      # モーダルが開くまで待機
      expect(page).to have_selector("#memoEditModal.show", wait: 10)

      # モーダル内の TipTap エディタに一意の文字列を入力
      new_content_suffix = SecureRandom.hex(4)
      new_content = "新規メモ E2E_#{new_content_suffix}"
      editor = find("#memoEditModal #rich-editor-root .ProseMirror[contenteditable='true']", wait: 10, match: :first)
      editor.click
      editor.send_keys(new_content)

      # 保存ボタンをクリック
      find("#memoEditModal button[title='保存']").click

      # 書籍詳細に戻ること
      expect(page).to(have_current_path(book_path(book)), -> { "current: #{page.current_path}" })
      expect(page).not_to have_selector("#memoEditModal.show", wait: 5)

      # DB に 1 件増え、その content に入力した文字列が含まれること
      book.reload
      expect(book.memos.count).to eq(1)
      created_memo = book.memos.last
      expect(created_memo.content).to include(new_content_suffix)
    end
  end
end
