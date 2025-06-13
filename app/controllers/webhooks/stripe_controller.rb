class Webhooks::StripeController < ApplicationController
  # Webhookは外部からのリクエストなのでCSRF保護を除外する
  protect_from_forgery except: :create

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
      )
    rescue JSON::ParserError => e
      render json: { error: "Invalid payload #{e.message}" }, status: 400 and return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature #{e.message}" }, status: 400 and return
    end

    # イベント種別ごとの処理
    case event.type
    when "customer.subscription.created"
      handle_subscription_created(event.data.object)
    when "customer.subscription.updated"
      handle_subscription_updated(event.data.object)
    when "customer.subscription.deleted"
      handle_subscription_deleted(event.data.object)
    end

    render json: { status: "success" }
  end

  private

  def handle_subscription_created(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    user.update(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status
    )

    Rails.logger.info "🔔 Subscription created for user ##{user.id} | Status: #{subscription.status}"
  end

  def handle_subscription_updated(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    user.update(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status
    )

    Rails.logger.info "🔁 Subscription updated for user ##{user.id} | Status: #{subscription.status}"
  end

  def handle_subscription_deleted(subscription)
    user = User.find_by(stripe_subscription_id: subscription.id)
    return unless user

    user.update(
      stripe_subscription_id: nil,
      subscription_status: subscription.status
    )

    Rails.logger.info "❌ Subscription deleted for user ##{user.id} | Status: #{subscription.status}"
  end
end
