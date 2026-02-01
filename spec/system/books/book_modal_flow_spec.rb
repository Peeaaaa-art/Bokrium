# frozen_string_literal: true

require "rails_helper"

RSpec.describe "書籍編集・削除モーダル（書籍詳細→設定ボタン→モーダル→編集/削除）", type: :system do
  let(:user) { create(:user) }
  let(:book) { create(:book, user: user) }

  before do
    driven_by :selenium_chrome_headless
    sign_in user
  end

  it "設定（ギア）ボタンをクリックするとモーダルが開く" do
    visit book_path(book)

    # ギアボタン（data-bs-target="#settingsModal"）をクリック
    find("button[data-bs-toggle='modal'][data-bs-target='#settingsModal']").click

    # モーダルが表示されること
    expect(page).to have_selector("#settingsModal.show", wait: 10)
    expect(page).to have_selector("#settingsModal .modal-title", text: /本の操作/, wait: 5)
  end

  it "モーダル内の「編集する」をクリックすると書籍編集ページに遷移する" do
    visit book_path(book)

    find("button[data-bs-toggle='modal'][data-bs-target='#settingsModal']").click
    expect(page).to have_selector("#settingsModal.show", wait: 10)

    # モーダル内の編集リンクをクリック
    find("#settingsModal a.modal-action-button.edit", text: "編集する").click

    expect(page).to have_current_path(edit_book_path(book), wait: 10)
  end

  it "モーダル内の「削除する」を実行すると一覧に戻る" do
    # 削除後も本が1冊残るようにする（0冊だと index が guest_books_path にリダイレクトし、guest_user が nil で落ちる）
    _other = create(:book, user: user)

    visit book_path(book)

    find("button[data-bs-toggle='modal'][data-bs-target='#settingsModal']").click
    expect(page).to have_selector("#settingsModal.show", wait: 10)

    # turbo_confirm の確認ダイアログを accept して削除ボタンをクリック
    accept_confirm do
      find("#settingsModal button.modal-action-button.delete", text: "削除する").click
    end

    expect(page).to have_current_path(books_path, wait: 10)
    expect(Book.exists?(book.id)).to be false
  end
end
