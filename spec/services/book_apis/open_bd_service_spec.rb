require 'rails_helper'

RSpec.describe BookApis::OpenBdService do
  describe '.fetch' do
    let(:isbn) { "9784041023444" }
    let(:endpoint) { "https://api.openbd.jp/v1/get?isbn=#{isbn}" }

    context '正常なレスポンスが返ってきた場合' do
      let(:response_body) do
        [
          {
            "summary" => {
              "title"     => "テストタイトル",
              "author"    => "テスト著者",
              "publisher" => "テスト出版社",
              "isbn"      => isbn,
              "page"      => "300",
              "cover"     => "http://example.com/cover.jpg"
            },
            "onix" => {
              "ProductSupply" => {
                "SupplyDetail" => {
                  "Price" => [
                    { "PriceAmount" => "2200" }
                  ]
                }
              }
            }
          }
        ].to_json
      end

      it '正しい書籍データを返す' do
        stub_request(:get, endpoint).to_return(status: 200, body: response_body)

        result = described_class.fetch(isbn)
        expect(result).to eq({
          title:      "テストタイトル",
          author:     "テスト著者",
          publisher:  "テスト出版社",
          isbn:       isbn,
          page:       300,
          book_cover: "http://example.com/cover.jpg",
          price:      2200
        })
      end
    end

    context '書籍データが見つからない場合' do
      it 'nilを返す' do
        stub_request(:get, endpoint).to_return(status: 200, body: [ nil ].to_json)

        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context 'HTTPレスポンスが失敗した場合' do
      it 'nilを返す' do
        stub_request(:get, endpoint).to_return(status: 500, body: "")

        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context '例外が発生した場合' do
      it 'nilを返す' do
        stub_request(:get, endpoint).to_raise(StandardError.new("接続失敗"))

        expect(Rails.logger).to receive(:error).with(/\[OpenBdService\] StandardError: 接続失敗/)
        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context 'タイムアウトした場合' do
      it 'ハングせずnilを返す' do
        stub_request(:get, endpoint).to_timeout

        expect(described_class.fetch(isbn)).to be_nil
      end
    end
  end
end
