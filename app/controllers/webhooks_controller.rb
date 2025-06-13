class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    webhook_secret = ENV["STRIPE_WEBHOOK_SECRET"]
    event = nil

    begin
      event = Stripe::Webhook.construct_event(payload, sig_header, webhook_secret)
    rescue JSON::ParserError => e
      render json: { error: "Invalid payload" }, status: 400 and return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature" }, status: 400 and return
    end

    # イベント種別ごとの処理
    case event.type
    when "checkout.session.completed"
      session = event.data.object
      handle_checkout_completed(session)
    when "customer.subscription.created"
      subscription = event.data.object
      handle_subscription_created(subscription)
    when "customer.subscription.deleted"
      subscription = event.data.object
      handle_subscription_deleted(subscription)
    when "customer.subscription.updated"
      subscription = event.data.object
      handle_subscription_updated(subscription)
    end

    render json: { message: "success" }
  end

  private

  def handle_checkout_completed(session)
    Rails.logger.info "[Stripe] Checkout completed: #{session.id}"
    # 必要ならDB更新処理など
  end

  def handle_subscription_created(subscription)
    Rails.logger.info "[Stripe] Subscription created: #{subscription.id}"
  end

  def handle_subscription_deleted(subscription)
    Rails.logger.info "[Stripe] Subscription deleted: #{subscription.id}"
  end

  def handle_subscription_updated(subscription)
    Rails.logger.info "[Stripe] Subscription updated: #{subscription.id}"
  end
end
