# frozen_string_literal: true

class CoverProxyController < ApplicationController
  # 外部書影のホットリンク対策を回避するため、サーバー経由で画像を取得して返す。
  ALLOWED_HOSTS = [
    "books.google.com",
    "books.google.co.jp",
    "thumbnail.image.rakuten.co.jp",
    "image.rakuten.co.jp",
    "rimg.jp",
    "img.hanmoto.com"
  ].freeze
  # リダイレクト先などで使われる Google の画像ホスト（サブドメイン多数のため suffix で許可）
  ALLOWED_HOST_SUFFIXES = [ ".googleusercontent.com", ".gstatic.com" ].freeze
  REDIRECT_LIMIT = 3

  skip_before_action :authenticate_user!
  before_action :validate_url

  def show
    url = @url
    REDIRECT_LIMIT.times do
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 5
      http.read_timeout = 10

      request = Net::HTTP::Get.new(uri.request_uri)
      request["User-Agent"] = "Bokrium/1.0"
      # Referer を送らないことで Google 等のホットリンクブロックを回避

      response = http.request(request)

      if response.is_a?(Net::HTTPRedirection)
        location = response["Location"]
        return head(:not_found) if location.blank?
        next_uri = URI.parse(URI.join(uri, location))
        return head(:forbidden) unless next_uri.scheme == "https" && allowed_host?(next_uri.host)
        url = next_uri.to_s
        next
      end

      unless response.is_a?(Net::HTTPSuccess)
        head :not_found
        return
      end

      content_type = response["Content-Type"]&.split(";")&.first&.strip || "image/jpeg"
      expires_in = 1.day
      headers["Cache-Control"] = "public, max-age=#{expires_in.to_i}"

      send_data response.body,
                type: content_type,
                disposition: "inline",
                status: :ok
      return
    end
    head :not_found
  end

  private

  def validate_url
    @url = params[:url].to_s.strip
    return head(:bad_request) if @url.blank?

    uri = URI.parse(@url)
    return head(:bad_request) unless uri.is_a?(URI::HTTP)
    return head(:bad_request) unless uri.scheme == "https"
    return head(:forbidden) unless allowed_host?(uri.host)
  rescue URI::InvalidURIError
    head :bad_request
  end

  def allowed_host?(host)
    self.class.allowed_host?(host)
  end

  def self.allowed_host?(host)
    return true if ALLOWED_HOSTS.include?(host)
    ALLOWED_HOST_SUFFIXES.any? { |suffix| host.end_with?(suffix) }
  end
end
