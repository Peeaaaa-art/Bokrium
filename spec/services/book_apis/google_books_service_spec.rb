require 'rails_helper'

RSpec.describe BookApis::GoogleBooksService do
  let(:endpoint) { "https://www.googleapis.com/books/v1/volumes" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("GOOGLE_BOOKS_API_KEY").and_return(nil)
  end

  describe ".fetch" do
    let(:isbn) { "9781234567890" }

    context "正常なレスポンスが返る場合" do
      it "正しい本の情報を返す" do
        stub_request(:get, endpoint)
          .with(query: hash_including("q" => "isbn:#{isbn}"))
          .to_return(
            status: 200,
            body: {
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
          )

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

      it "Origin/RefererヘッダーにAPP_HOSTを付与する(APIキーのリファラー制限対策)" do
        allow(ENV).to receive(:[]).with("APP_HOST").and_return("https://bokrium.com")

        stub_request(:get, endpoint)
          .with(
            query: hash_including("q" => "isbn:#{isbn}"),
            headers: { "Origin" => "https://bokrium.com", "Referer" => "https://bokrium.com/" }
          )
          .to_return(status: 200, body: { items: [] }.to_json)

        described_class.fetch(isbn)
        expect(WebMock).to have_requested(:get, endpoint).with(
          query: hash_including("q" => "isbn:#{isbn}"),
          headers: { "Origin" => "https://bokrium.com", "Referer" => "https://bokrium.com/" }
        )
      end
    end

    context "APIキーが設定されている場合" do
      it "keyパラメータを付与してリクエストする" do
        allow(ENV).to receive(:[]).with("GOOGLE_BOOKS_API_KEY").and_return("test_api_key")

        stub_request(:get, endpoint)
          .with(query: hash_including("q" => "isbn:#{isbn}", "key" => "test_api_key"))
          .to_return(status: 200, body: { items: [] }.to_json)

        described_class.fetch(isbn)
        expect(WebMock).to have_requested(:get, endpoint).with(query: hash_including("key" => "test_api_key"))
      end
    end

    context "異常なレスポンスが返る場合" do
      it "nilを返し、警告ログを出力する" do
        stub_request(:get, endpoint)
          .with(query: hash_including("q" => "isbn:#{isbn}"))
          .to_return(status: 429, body: "quota exceeded")

        expect(Rails.logger).to receive(:warn).with(/\[GoogleBooksService\] Unexpected response: 429/)
        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context "例外が発生した場合" do
      it "nilを返し、エラーログを出力する" do
        stub_request(:get, endpoint)
          .with(query: hash_including("q" => "isbn:#{isbn}"))
          .to_raise(StandardError.new("エラー発生"))

        expect(Rails.logger).to receive(:error).with(/\[GoogleBooksService\]\[ISBN\] StandardError: エラー発生/)
        expect(described_class.fetch(isbn)).to be_nil
      end
    end
  end

  describe ".fetch_by_title_or_author" do
    let(:query) { "テスト" }

    context "正常なレスポンスが返る場合" do
      it "期待される形式で本の一覧を返す" do
        stub_request(:get, endpoint)
          .with(query: hash_including("q" => query, "maxResults" => "30", "startIndex" => "0"))
          .to_return(
            status: 200,
            body: {
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
          )

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

    context "2ページ目を取得する場合" do
      it "startIndexをずらしてリクエストする" do
        stub_request(:get, endpoint)
          .with(query: hash_including("q" => query, "maxResults" => "30", "startIndex" => "30"))
          .to_return(status: 200, body: { totalItems: 0, items: [] }.to_json)

        described_class.fetch_by_title_or_author(query, 2)
        expect(WebMock).to have_requested(:get, endpoint).with(query: hash_including("startIndex" => "30"))
      end
    end

    context "異常なレスポンスが返る場合" do
      it "空の結果を返し、警告ログを出力する" do
        stub_request(:get, endpoint)
          .with(query: hash_including("q" => query))
          .to_return(status: 429, body: "quota exceeded")

        expect(Rails.logger).to receive(:warn).with(/\[GoogleBooksService\] Unexpected response: 429/)
        result = described_class.fetch_by_title_or_author(query)
        expect(result).to eq({ items: [], total_count: 0 })
      end
    end

    context "例外が発生した場合" do
      it "空の結果を返し、エラーログを出力する" do
        stub_request(:get, endpoint)
          .with(query: hash_including("q" => query))
          .to_raise(StandardError.new("search error"))

        expect(Rails.logger).to receive(:error).with(/\[GoogleBooksService\]\[Title\/Author\] StandardError: search error/)
        expect(described_class.fetch_by_title_or_author(query)).to eq({ items: [], total_count: 0 })
      end
    end
  end
end
