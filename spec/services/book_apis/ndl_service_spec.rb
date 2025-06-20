require 'rails_helper'
require 'net/http'

RSpec.describe BookApis::NdlService do
  describe '.fetch' do
    let(:isbn) { '9781234567890' }

    let(:sample_response_xml) do
      <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <rss xmlns:dc="http://purl.org/dc/elements/1.1/">
          <channel>
            <item>
              <title>NDLテストタイトル</title>
              <creator>NDL著者</creator>
              <publisher>NDL出版社</publisher>
            </item>
          </channel>
        </rss>
      XML
    end

    it '書籍情報を正しく取得できる' do
      uri = URI("https://iss.ndl.go.jp/api/opensearch?isbn=#{isbn}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      response = Net::HTTPSuccess.new('1.1', '200', 'OK')
      allow(response).to receive(:body).and_return(sample_response_xml)
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:request).and_return(response)


      result = described_class.fetch(isbn)

      expect(result).to eq(
        title: "NDLテストタイトル",
        author: "NDL著者",
        publisher: "NDL出版社",
        isbn: isbn,
        price: nil,
        page: nil
      )
    end
  end
end
