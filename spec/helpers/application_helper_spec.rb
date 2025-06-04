require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#nav_link_to" do
    it "adds active class when on current page" do
      allow(helper).to receive(:current_page?).with("/books").and_return(true)
      html = helper.nav_link_to("本棚", "/books")
      expect(html).to include("active")
      expect(html).to include("fw-semibold")
    end

    it "does not add active class when not on current page" do
      allow(helper).to receive(:current_page?).with("/books").and_return(false)
      html = helper.nav_link_to("本棚", "/books")
      expect(html).not_to include("active fw-semibold")
    end
  end

  describe "#books_index_path" do
    let(:user) { create(:user) }

    it "returns guest_books_path when not signed in" do
      allow(helper).to receive(:user_signed_in?).and_return(false)
      expect(helper.books_index_path).to eq(guest_books_path)
    end

    it "returns books_path when user has books" do
      create(:book, user: user)
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      expect(helper.books_index_path).to eq(books_path)
    end

    it "returns guest_books_path when user has no books" do
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      expect(helper.books_index_path).to eq(guest_books_path)
    end
  end

  describe "#books_index_active_class" do
    it "returns active when on correct path" do
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:request).and_return(double(path: "/books"))
      expect(helper.books_index_active_class).to eq("active")
    end

    it "returns empty string when not on books path" do
      allow(helper).to receive(:user_signed_in?).and_return(false)
      allow(helper).to receive(:request).and_return(double(path: "/other"))
      expect(helper.books_index_active_class).to eq("")
    end
  end

  describe "#book_link_path" do
    let(:user) { create(:user) }
    let(:book) { create(:book, user: user) }

    it "returns guest_starter_book_path when @starter_book is true" do
      helper.instance_variable_set(:@starter_book, true)
      expect(helper.book_link_path(book)).to eq(guest_starter_book_path(book))
    end

    it "returns book_path when user has books" do
      create(:book, user: user)
      helper.instance_variable_set(:@starter_book, false)
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      expect(helper.book_link_path(book)).to eq(book_path(book))
    end

    it "returns guest_book_path when user has no books" do
      helper.instance_variable_set(:@starter_book, false)
      allow(helper).to receive(:user_signed_in?).and_return(true)
      allow(helper).to receive(:current_user).and_return(user)
      allow(user.books).to receive(:exists?).and_return(false)

      expect(helper.book_link_path(book)).to eq(guest_book_path(book))
    end
  end

  describe "#lazy_image_tag" do
    it "adds loading lazy attribute" do
      expect(helper).to receive(:image_tag).with("sample.png", hash_including(loading: "lazy"))
      helper.lazy_image_tag("sample.png")
    end
  end
end
