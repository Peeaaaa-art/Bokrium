require 'rails_helper'
require 'net/http'

RSpec.describe BookApis::GoogleBooksService do
  describe ".fetch" do
    let(:isbn) { "9781234567890" }

    context "正常なレスポンスが返る場合" do
      before do
        response_body = {
          items: [
            {
              volumeInfo: {
                title: "テスト本",
                authors: [ "山田太郎" ],
                publisher: "テスト出版社",
                imageLinks: { thumbnail: "http://example.com/image.jpg" },
                pageCount: 123
              }
            }
          ]
        }.to_json

        response = instance_double(Net::HTTPOK, body: response_body)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).and_return(response)
      end

      it "正しい本の情報を返す" do
        result = described_class.fetch(isbn)
        expect(result).to eq({
          isbn: isbn,
          price: nil,
          title: "テスト本",
          author: "山田太郎",
          publisher: "テスト出版社",
          book_cover: "https://example.com/image.jpg",
          page: 123
        })
      end
    end

    context "異常なレスポンスが返る場合" do
      it "nilを返す" do
        allow(Net::HTTP).to receive(:get_response).and_return(instance_double(Net::HTTPInternalServerError))
        expect(described_class.fetch(isbn)).to be_nil
      end
    end
  end

  describe ".fetch_by_title_or_author" do
    let(:query) { "テスト" }

    context "正常なレスポンスが返る場合" do
      before do
        response_body = {
          totalItems: 1,
          items: [
            {
              volumeInfo: {
                title: "検索本",
                authors: [ "著者名" ],
                publisher: "出版社名",
                imageLinks: { thumbnail: "http://example.com/cover.jpg" },
                industryIdentifiers: [
                  { type: "ISBN_13", identifier: "9781111111111" }
                ]
              }
            }
          ]
        }.to_json

        response = instance_double(Net::HTTPOK, body: response_body)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).and_return(response)
      end

      it "期待される形式で本の一覧を返す" do
        result = described_class.fetch_by_title_or_author(query)
        expect(result[:items].first).to include(
          title: "検索本",
          author: "著者名",
          publisher: "出版社名",
          isbn: "9781111111111",
          price: nil,
          book_cover: "https://example.com/cover.jpg"
        )
        expect(result[:total_count]).to eq(1)
      end
    end

    context "異常なレスポンスが返る場合" do
      it "空の結果を返す" do
        allow(Net::HTTP).to receive(:get_response).and_return(instance_double(Net::HTTPInternalServerError))
        result = described_class.fetch_by_title_or_author(query)
        expect(result).to eq({ items: [], total_count: 0 })
      end
    end
  end
end
