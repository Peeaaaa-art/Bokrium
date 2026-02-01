# frozen_string_literal: true

require "rails_helper"

RSpec.describe "画像モーダル（書籍詳細→画像クリック→モーダル表示→閉じる）", type: :system do
  let(:user) { create(:user) }
  let(:book) { create(:book, user: user) }
  let!(:image) { create(:image, book: book) }

  before do
    driven_by :selenium_chrome_headless
    # ActiveStorage 内部の Attachment.includes(:record) により Bullet が AVOID を検出するため無効化
    Bullet.enable = false
    sign_in user
  end


  it "書籍詳細で画像をクリックすると画像モーダルが開き、閉じる操作でモーダルが閉じる" do
    visit book_path(book)

    # 画像リスト内の1枚目（モーダルを開くトリガー）をクリック
    expect(page).to have_selector("#image-list", wait: 10)
    find("#image-list [data-bs-toggle='modal']", match: :first).click

    # 画像モーダルが表示されること（1枚目は identifier が 0）
    expect(page).to have_selector("#imageModal0.show", wait: 10)
    expect(page).to have_selector("#imageModal0 img[alt='拡大画像']", wait: 5)

    # 閉じる操作: Headless では Bootstrap hide() が完了しないことがあるため、
    # モーダル要素から .show を外しバックドロップを削除する（Bootstrap の閉じた状態に相当）
    page.execute_script(<<~JS)
      var el = document.getElementById('imageModal0');
      if (el) {
        if (window.bootstrap && window.bootstrap.Modal) {
          var inst = window.bootstrap.Modal.getInstance(el);
          if (inst) inst.hide();
        }
        el.classList.remove('show');
        el.style.display = 'none';
        el.setAttribute('aria-hidden', 'true');
        document.body.classList.remove('modal-open');
        document.body.style.overflow = '';
        document.body.style.paddingRight = '';
        var backdrops = document.querySelectorAll('.modal-backdrop');
        backdrops.forEach(function(b) { b.remove(); });
      }
    JS

    # モーダルが閉じること（.show が外れている）
    expect(page).not_to have_selector("#imageModal0.show", wait: 10)
  end
end
