require 'rails_helper'

RSpec.describe BookApis::HttpClient do
  describe '.get' do
    let(:url) { "https://example.com/api" }

    it 'GETリクエストを送りレスポンスを返す' do
      stub_request(:get, url).to_return(status: 200, body: "ok")

      response = described_class.get(URI.parse(url))
      expect(response).to be_a(Net::HTTPSuccess)
      expect(response.body).to eq("ok")
    end

    it '指定したヘッダを付与する' do
      stub = stub_request(:get, url)
        .with(headers: { "Origin" => "https://bokrium.com" })
        .to_return(status: 200, body: "")

      described_class.get(URI.parse(url), headers: { "Origin" => "https://bokrium.com" })
      expect(stub).to have_been_requested
    end

    it 'open/read timeoutを5秒に設定する' do
      stub_request(:get, url).to_return(status: 200, body: "")

      http_instances = []
      allow(Net::HTTP).to receive(:new).and_wrap_original do |original, *args|
        original.call(*args).tap { |http| http_instances << http }
      end

      described_class.get(URI.parse(url))

      expect(http_instances.first.open_timeout).to eq(5)
      expect(http_instances.first.read_timeout).to eq(5)
    end
  end

  describe '.request_origin' do
    before do
      allow(ENV).to receive(:[]).and_call_original
    end

    it 'APP_HOST未設定なら本番ドメインを返す' do
      allow(ENV).to receive(:[]).with("APP_HOST").and_return(nil)
      expect(described_class.request_origin).to eq("https://bokrium.com")
    end

    it 'スキームなしのAPP_HOSTにはhttpsを補う' do
      allow(ENV).to receive(:[]).with("APP_HOST").and_return("bokrium.com")
      expect(described_class.request_origin).to eq("https://bokrium.com")
    end

    it '既定外ポートは維持する' do
      allow(ENV).to receive(:[]).with("APP_HOST").and_return("http://localhost:3000")
      expect(described_class.request_origin).to eq("http://localhost:3000")
    end
  end

  describe '.request_referer' do
    it 'originに/を付けた値を返す' do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("APP_HOST").and_return("bokrium.com")
      expect(described_class.request_referer).to eq("https://bokrium.com/")
    end
  end
end
