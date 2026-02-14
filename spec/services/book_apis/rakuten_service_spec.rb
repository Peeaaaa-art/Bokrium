require "rails_helper"

RSpec.describe BookApis::RakutenService do
  let(:endpoint) { "https://openapi.rakuten.co.jp/services/api/BooksBook/Search/20170404" }
  let(:application_id) { "test_application_id" }
  let(:access_key) { "test_access_key" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("RAKUTEN_APPLICATION_ID").and_return(application_id)
    allow(ENV).to receive(:[]).with("RAKUTEN_ACCESS_KEY").and_return(access_key)
  end

  describe ".fetch" do
    let(:isbn) { "9781234567890" }

    context "正常に書籍情報が取得できる場合" do
      it "書籍データを返す" do
        stub_request(:get, endpoint)
          .with(
            query: hash_including(
              "applicationId" => application_id,
              "accessKey" => access_key,
              "formatVersion" => "2",
              "isbn" => isbn
            ),
            headers: { "Authorization" => "Bearer #{access_key}" }
          )
          .to_return(
            status: 200,
            body: {
              count: 1,
              items: [
                {
                  item: {
                    title: "楽天本タイトル",
                    author: "楽天著者",
                    publisherName: "楽天出版社",
                    isbn: isbn,
                    itemPrice: 1980,
                    largeImageUrl: "http://example.com/book.jpg",
                    itemUrl: "https://books.rakuten.co.jp/rb/12345678/"
                  }
                }
              ]
            }.to_json
          )

        result = described_class.fetch(isbn)

        expect(result).to eq({
          title: "楽天本タイトル",
          author: "楽天著者",
          publisher: "楽天出版社",
          isbn: isbn,
          price: 1980,
          book_cover: "http://example.com/book.jpg",
          page: nil,
          affiliate_url: "https://books.rakuten.co.jp/rb/12345678/"
        })
      end
    end

    context "画像がnoimageの場合" do
      it "book_coverをnilにする" do
        stub_request(:get, endpoint)
          .with(
            query: hash_including(
              "applicationId" => application_id,
              "accessKey" => access_key,
              "formatVersion" => "2",
              "isbn" => isbn
            ),
            headers: { "Authorization" => "Bearer #{access_key}" }
          )
          .to_return(
            status: 200,
            body: {
              count: 1,
              Items: [
                {
                  Item: {
                    title: "NoImage本",
                    author: "著者",
                    publisherName: "出版社",
                    isbn: isbn,
                    itemPrice: 1200,
                    largeImageUrl: "http://example.com/noimage.jpg",
                    itemUrl: "https://books.rakuten.co.jp/rb/12345678/"
                  }
                }
              ]
            }.to_json
          )

        result = described_class.fetch(isbn)
        expect(result[:book_cover]).to be_nil
      end
    end

    context "検索結果が空の場合" do
      it "nilを返す" do
        stub_request(:get, endpoint)
          .with(
            query: hash_including(
              "applicationId" => application_id,
              "accessKey" => access_key,
              "formatVersion" => "2",
              "isbn" => isbn
            ),
            headers: { "Authorization" => "Bearer #{access_key}" }
          )
          .to_return(status: 200, body: { count: 0, Items: [] }.to_json)
        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context "HTTPレスポンスが失敗した場合" do
      it "nilを返す" do
        stub_request(:get, endpoint)
          .with(
            query: hash_including(
              "applicationId" => application_id,
              "accessKey" => access_key,
              "formatVersion" => "2",
              "isbn" => isbn
            ),
            headers: { "Authorization" => "Bearer #{access_key}" }
          )
          .to_return(status: 500, body: "error")
        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context "例外が発生した場合" do
      it "nilを返し、エラーログを出力する" do
        stub_request(:get, endpoint)
          .with(
            query: hash_including(
              "applicationId" => application_id,
              "accessKey" => access_key,
              "formatVersion" => "2",
              "isbn" => isbn
            ),
            headers: { "Authorization" => "Bearer #{access_key}" }
          )
          .to_raise(StandardError.new("エラー発生"))

        expect(Rails.logger).to receive(:error).with(/\[RakutenService\]\[ISBN\] StandardError: エラー発生/)
        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context "認証情報が欠けている場合" do
      it "nilを返し、警告ログを出力する" do
        allow(ENV).to receive(:[]).with("RAKUTEN_ACCESS_KEY").and_return(nil)

        expect(Rails.logger).to receive(:warn).with(/\[RakutenService\] Missing credentials/)
        expect(described_class.fetch(isbn)).to be_nil
      end
    end
  end

  describe ".search_by_title_or_author" do
    let(:query) { "Ruby" }

    context "title検索が成功する場合" do
      it "検索結果と件数を返す" do
        stub_request(:get, endpoint)
          .with(query: hash_including("title" => query, "page" => "2", "hits" => "30"))
          .to_return(
            status: 200,
            body: {
              count: 42,
              items: [
                {
                  item: {
                    title: "実践Ruby",
                    author: "著者A",
                    publisherName: "出版社A",
                    isbn: "9781111111111",
                    itemPrice: 3000,
                    mediumImageUrl: "http://example.com/ruby.jpg",
                    affiliateUrl: "https://hb.afl.rakuten.co.jp/example"
                  }
                }
              ]
            }.to_json
          )

        result = described_class.search_by_title_or_author(type: "title", query: query, page: 2, hits: 30)

        expect(result[:total_count]).to eq(42)
        expect(result[:items]).to eq([
          {
            title: "実践Ruby",
            author: "著者A",
            publisher: "出版社A",
            isbn: "9781111111111",
            price: 3000,
            book_cover: "http://example.com/ruby.jpg",
            page: nil,
            affiliate_url: "https://hb.afl.rakuten.co.jp/example"
          }
        ])
      end
    end

    context "author検索が成功する場合" do
      it "authorパラメータで検索する" do
        stub_request(:get, endpoint)
          .with(query: hash_including("author" => "村上"))
          .to_return(status: 200, body: { count: 0, Items: [] }.to_json)

        described_class.search_by_title_or_author(type: "author", query: "村上")
        expect(WebMock).to have_requested(:get, endpoint).with(query: hash_including("author" => "村上"))
      end
    end

    context "HTTPレスポンスが失敗した場合" do
      it "空の結果を返す" do
        stub_request(:get, endpoint)
          .with(
            query: hash_including(
              "applicationId" => application_id,
              "accessKey" => access_key,
              "formatVersion" => "2",
              "title" => query
            ),
            headers: { "Authorization" => "Bearer #{access_key}" }
          )
          .to_return(status: 503, body: "unavailable")
        expect(described_class.search_by_title_or_author(type: "title", query: query)).to eq({ items: [], total_count: 0 })
      end
    end

    context "例外が発生した場合" do
      it "空の結果を返し、エラーログを出力する" do
        stub_request(:get, endpoint)
          .with(
            query: hash_including(
              "applicationId" => application_id,
              "accessKey" => access_key,
              "formatVersion" => "2",
              "title" => query
            ),
            headers: { "Authorization" => "Bearer #{access_key}" }
          )
          .to_raise(StandardError.new("search error"))

        expect(Rails.logger).to receive(:error).with(/\[RakutenService\]\[Search\] StandardError: search error/)
        expect(described_class.search_by_title_or_author(type: "title", query: query)).to eq({ items: [], total_count: 0 })
      end
    end

    context "認証情報が欠けている場合" do
      it "空の結果を返し、警告ログを出力する" do
        allow(ENV).to receive(:[]).with("RAKUTEN_APPLICATION_ID").and_return(nil)

        expect(Rails.logger).to receive(:warn).with(/\[RakutenService\] Missing credentials/)
        expect(described_class.search_by_title_or_author(type: "title", query: query)).to eq({ items: [], total_count: 0 })
      end
    end
  end
end
