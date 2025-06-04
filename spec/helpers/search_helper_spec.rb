require 'rails_helper'

RSpec.describe SearchHelper, type: :helper do
  describe "#pagination_path_for" do
    it "returns valid path when query and type are present" do
      path = helper.pagination_path_for(2, { query: "Ruby", type: "title", engine: "rakuten" })
      expect(path).to include("page=2")
      expect(path).to include("type=title")
    end

    it "returns '#' when query or type is missing" do
      expect(helper.pagination_path_for(1, {})).to eq("#")
    end
  end

  describe "#search_result_range" do
    it "returns correct range string" do
      allow(helper).to receive(:params).and_return({ page: "2" })
      books = Array.new(30) { double("Book") }
      result = helper.search_result_range(books, 120, per_page: 30)
      expect(result).to include("（120件中 31〜60件目を表示）")
    end
  end

  describe "#placeholder_for" do
    it "returns I18n translated value" do
      expect(helper.placeholder_for("title")).to eq(I18n.t("placeholders.title"))
    end

    it "falls back to default if key is missing" do
      expect(helper.placeholder_for(nil)).to eq(I18n.t("placeholders.title"))
    end
  end
end
