require "rails_helper"

RSpec.describe Books::IsbnResultComponent, type: :component do
  let(:book_data) do
    {
      title: "コンポーネント設計の教科書",
      author: "山田 太郎",
      publisher: "技術評論社",
      isbn: "9781234567890",
      book_cover: "https://example.com/cover.jpg"
    }
  end

context "when user is logged in" do
  before do
    allow_any_instance_of(described_class).to receive(:logged_in?).and_return(true)
  end

it "renders book info and an active submit button" do
  html = render_inline(described_class.new(book_data: book_data)).to_html
  doc = Nokogiri::HTML.fragment(html)

  expect(doc.text).to include("コンポーネント設計の教科書")
  expect(doc.text).to include("山田 太郎")
  expect(doc.text).to include("技術評論社")

  img = doc.at_css("img")
  expect(img["src"]).to eq("https://example.com/cover.jpg")

  isbn_input = doc.at_css('input#book_isbn')
  expect(isbn_input["value"]).to eq("9781234567890")

  button = doc.at_css("button[type='submit']")
  expect(button.text).to include("本棚に追加")
  expect(button["disabled"]).to be_nil
end
  end
  context "when user is not logged in" do
    before do
      allow_any_instance_of(described_class).to receive(:logged_in?).and_return(false)
    end

    it "renders disabled button with tooltip text" do
      render_inline(described_class.new(book_data: book_data))

      expect(page).to have_text("コンポーネント設計の教科書")
      expect(page).to have_button("本棚に追加", disabled: true)
      expect(page).to have_selector("button[title='ログインすると追加できます']")
    end
  end

  context "when book_cover is nil" do
    before do
      allow_any_instance_of(described_class).to receive(:logged_in?).and_return(true)
    end

    it "renders no-cover fallback box" do
      data = book_data.merge(book_cover: nil)
      render_inline(described_class.new(book_data: data))

      expect(page).to have_selector("span.no-cover", text: /コンポーネント設計の/)
      expect(page).not_to have_selector("img")
    end
  end
end
