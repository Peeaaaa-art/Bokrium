require 'rails_helper'
require 'net/http'

RSpec.describe BookApis::OpenBdService do
  describe '.fetch' do
    let(:isbn) { "9784041023444" }
    let(:uri) { URI.parse("https://api.openbd.jp/v1/get?isbn=#{isbn}") }

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
        success_response = instance_double(Net::HTTPSuccess, body: response_body)
        allow(success_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).with(uri).and_return(success_response)

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
        response = instance_double(Net::HTTPSuccess, body: [ nil ].to_json)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).with(uri).and_return(response)

        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context 'HTTPレスポンスが失敗した場合' do
      it 'nilを返す' do
        fail_response = instance_double(Net::HTTPInternalServerError)
        allow(fail_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(Net::HTTP).to receive(:get_response).with(uri).and_return(fail_response)

        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context '例外が発生した場合' do
      it 'nilを返す' do
        allow(Net::HTTP).to receive(:get_response).with(uri).and_raise(StandardError.new("接続失敗"))

        expect(Rails.logger).to receive(:error).with(/\[OpenBdService\] 接続失敗/)
        expect(described_class.fetch(isbn)).to be_nil
      end
    end
  end
end
