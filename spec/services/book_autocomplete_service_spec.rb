require "rails_helper"

RSpec.describe BookAutocompleteService do
  let(:user) { create(:user) }

  describe "#call" do
    it "タイトルに一致する自分の本を候補として返す" do
      create(:book, title: "Ruby入門", author: "山田", user: user)
      create(:book, title: "Python入門", author: "佐藤", user: user)

      results = described_class.new(term: "Ruby", scope: "mine", user: user).call

      expect(results).to contain_exactly(
        include(value: "Ruby入門", label: "Ruby入門（山田）")
      )
    end

    it "著者に一致するサンプル本を候補として返す" do
      create(:book, title: "ゲストの本", author: "夏目漱石", user: user)

      results = described_class.new(term: "漱石", scope: "guest", user: user).call

      expect(results).to contain_exactly(
        include(value: "ゲストの本", label: "ゲストの本（夏目漱石）")
      )
    end

    it "未対応scopeでは候補を返さない" do
      create(:book, title: "Ruby入門", user: user)

      results = described_class.new(term: "Ruby", scope: "public", user: user).call

      expect(results).to eq([])
    end
  end
end
