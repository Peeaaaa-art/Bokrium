class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
      )
    rescue JSON::ParserError => e
      render json: { error: "Invalid payload #{e}" }, status: 400 and return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature #{e}" }, status: 400 and return
    end

    case event.type
    when "checkout.session.completed"
      session = event.data.object
      # ここでユーザーに紐付ける処理などを書く
      puts "✅ Session completed: #{session.id}"
    when "customer.subscription.created"
      puts "🟢 Subscription created"
    when "customer.subscription.deleted"
      puts "🔴 Subscription canceled"
    when "customer.subscription.updated"
      puts "🟡 Subscription updated"
    end

    render json: { message: "success" }
  end
end
