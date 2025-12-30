require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#nav_link_to" do
    it "現在のページと一致する場合にactiveクラスが付与されること" do
      allow(helper).to receive(:current_page?).with("/books").and_return(true)
      html = helper.nav_link_to("本棚", "/books")
      expect(html).to include("active")
      expect(html).to include("fw-semibold")
    end

    it "現在のページと一致しない場合はactiveクラスが付与されないこと" do
      allow(helper).to receive(:current_page?).with("/books").and_return(false)
      html = helper.nav_link_to("本棚", "/books")
      expect(html).not_to include("active fw-semibold")
    end
  end


  describe "#lazy_image_tag" do
    it "loading=\"lazy\" 属性が付与されること" do
      expect(helper).to receive(:image_tag).with("sample.png", hash_including(loading: "lazy"))
      helper.lazy_image_tag("sample.png")
    end
  end

  describe "#book_added_message" do
    let(:book) { double("Book", id: 123, title: "テスト本のタイトル") }

    before do
      allow(helper).to receive(:book_path).with(book).and_return("/books/123")
    end

    it "本のタイトルへのリンクを含むメッセージを返すこと" do
      message = helper.book_added_message(book)
      expect(message).to include("本棚に")
      expect(message).to include("『テスト本のタイトル』")
      expect(message).to include("を追加しました")
      expect(message).to include('<a href="/books/123">')
    end

    it "長いタイトルが切り詰められること" do
      long_book = double("Book", id: 456, title: "これは非常に長いタイトルで、40文字以上のものを用意しておきますね。ApplicationControllerで40を代入しています")
      allow(helper).to receive(:book_path).with(long_book).and_return("/books/456")

      message = helper.book_added_message(long_book)
      truncated = "これは非常に長いタイトルで、40文字以上のものを用意しておきますね。ApplicationControllerで40を代入しています".truncate(ApplicationController::TITLE_TRUNCATE_LIMIT)
      expect(message).to include(truncated)
    end

    it "XSS攻撃を防ぐためにタイトルがエスケープされること" do
      malicious_book = double("Book", id: 789, title: "<script>alert('xss')</script>")
      allow(helper).to receive(:book_path).with(malicious_book).and_return("/books/789")

      message = helper.book_added_message(malicious_book)
      expect(message).not_to include("<script>")
      # sanitizeによって二重エスケープされる
      expect(message).to include("&amp;lt;script&amp;gt;")
    end

    it "aタグとhref属性のみが許可されること" do
      message = helper.book_added_message(book)
      expect(message).to include('<a href="/books/123">')
      # 他のHTMLタグは含まれないことを確認
      expect(message).not_to match(/<(?!a|\/a)/)
    end
  end
end
