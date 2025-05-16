# app/controllers/line_webhooks_controller.rb
class LineWebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def callback
    body = request.body.read
    signature = request.env["HTTP_X_LINE_SIGNATURE"]
    parser = Line::Bot::V2::WebhookParser.new(channel_secret: ENV["LINE_CHANNEL_SECRET"])

    begin
      events = parser.parse(body: body, signature: signature)
    rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
      return head :bad_request
    end

    events.each do |event|
      user_id = event.source.user_id
      Rails.logger.info "[LINE] user_id: #{user_id}"
      # ここでUserモデルに保存するなど
    end

    head :ok
  end
end
