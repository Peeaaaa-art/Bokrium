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

  describe "#books_index_path" do
    let(:user) { create(:user) }

    it "未ログインの場合はguest_books_pathを返すこと" do
      allow(helper).to receive(:user_signed_in?).and_return(false)
      expect(helper.books_index_path).to eq(guest_books_path)
    end

    it "ユーザーが書籍を持っている場合はbooks_pathを返すこと" do
      create(:book, user: user)
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      expect(helper.books_index_path).to eq(books_path)
    end

    it "ユーザーが書籍を持っていない場合はguest_books_pathを返すこと" do
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      expect(helper.books_index_path).to eq(guest_books_path)
    end
  end

  describe "#books_index_active_class" do
    it "現在のパスが本棚ページの場合はactiveを返すこと" do
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:request).and_return(double(path: "/books"))
      expect(helper.books_index_active_class).to eq("active")
    end

    it "現在のパスが本棚ページでない場合は空文字を返すこと" do
      allow(helper).to receive(:user_signed_in?).and_return(false)
      allow(helper).to receive(:request).and_return(double(path: "/other"))
      expect(helper.books_index_active_class).to eq("")
    end
  end

  describe "#book_link_path" do
    let(:user) { create(:user) }
    let(:book) { create(:book, user: user) }

    it "@starter_bookがtrueの場合はguest_starter_book_pathを返すこと" do
      helper.instance_variable_set(:@starter_book, true)
      expect(helper.book_link_path(book)).to eq(guest_starter_book_path(book))
    end

    it "ユーザーが書籍を持っている場合はbook_pathを返すこと" do
      create(:book, user: user)
      helper.instance_variable_set(:@starter_book, false)
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      expect(helper.book_link_path(book)).to eq(book_path(book))
    end

    it "ユーザーが書籍を持っていない場合はguest_book_pathを返すこと" do
      helper.instance_variable_set(:@starter_book, false)
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      allow(user.books).to receive(:exists?).and_return(false)

      expect(helper.book_link_path(book)).to eq(guest_book_path(book))
    end
  end

  describe "#lazy_image_tag" do
    it "loading=\"lazy\" 属性が付与されること" do
      expect(helper).to receive(:image_tag).with("sample.png", hash_including(loading: "lazy"))
      helper.lazy_image_tag("sample.png")
    end
  end
end
