require 'rails_helper'

RSpec.describe BookApis::RakutenService do
  describe '.fetch' do
    let(:isbn) { '9781234567890' }

    context '正常に書籍情報が取得できる場合' do
      let(:mock_item) do
        instance_double("RakutenWebService::Books::Book", {
          title: "楽天本タイトル",
          author: "楽天著者",
          publisher_name: "楽天出版社",
          isbn: isbn,
          item_price: 1980,
          large_image_url: "http://example.com/book.jpg",
          item_url: "https://books.rakuten.co.jp/rb/12345678/"
        })
      end

      it '書籍データを返す' do
        allow(RakutenWebService::Books::Book).to receive(:search).with(isbn: isbn).and_return([ mock_item ])

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

    context '画像がnoimageの場合' do
      it 'book_coverをnilにする' do
        mock_item = instance_double("RakutenWebService::Books::Book",
          title: "NoImage本",
          author: "著者",
          publisher_name: "出版社",
          isbn: isbn,
          item_price: 1200,
          large_image_url: "http://example.com/noimage.jpg",
          item_url: "https://books.rakuten.co.jp/rb/12345678/"
        )

        allow(RakutenWebService::Books::Book).to receive(:search).with(isbn: isbn).and_return([ mock_item ])

        result = described_class.fetch(isbn)
        expect(result[:book_cover]).to be_nil
      end
    end

    context '検索結果が空の場合' do
      it 'nilを返す' do
        allow(RakutenWebService::Books::Book).to receive(:search).with(isbn: isbn).and_return([])

        expect(described_class.fetch(isbn)).to be_nil
      end
    end

    context 'RakutenWebService::Error が発生した場合' do
      it 'nilを返し、エラーログを出力する' do
        allow(RakutenWebService::Books::Book).to receive(:search).with(isbn: isbn)
          .and_raise(RakutenWebService::Error.new("エラー発生"))

        expect(Rails.logger).to receive(:error).with(/\[RakutenService\] エラー発生/)

        expect(described_class.fetch(isbn)).to be_nil
      end
    end
  end
end
