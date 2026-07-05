module BookApis
  # 外部書誌API(OpenBD / Rakuten / Google Books / NDL)共通のHTTP呼び出しユーティリティ。
  # 外部の無応答でPumaスレッドを塞がないよう、全サービスに同一のタイムアウトを適用する。
  module HttpClient
    require "net/http"
    require "uri"

    OPEN_TIMEOUT = 5
    READ_TIMEOUT = 5

    module_function

    def get(uri, headers: {})
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT

      req = Net::HTTP::Get.new(uri)
      headers.each { |key, value| req[key] = value }

      http.request(req)
    end

    # Google Cloud・楽天のAPIキーにHTTPリファラー制限をかけているため、
    # サーバーサイドのNet::HTTPが自動付与しないOrigin/Refererを明示する
    def request_origin
      raw = ENV["APP_HOST"].to_s.strip
      raw = "https://bokrium.com" if raw.blank?
      normalized = raw.match?(/\Ahttps?:\/\//) ? raw : "https://#{raw}"
      uri = URI.parse(normalized)
      origin = +"#{uri.scheme}://#{uri.host}"
      origin << ":#{uri.port}" if uri.port && uri.port != uri.default_port
      origin
    rescue URI::InvalidURIError
      "https://bokrium.com"
    end

    def request_referer
      "#{request_origin}/"
    end
  end
end
