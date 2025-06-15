class Webhooks::StripeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    payload = request.body.read
    sig_header = request.env["HTTP_STRIPE_SIGNATURE"]
    event = nil

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, ENV["STRIPE_WEBHOOK_SECRET"]
      )

      case event.type
      when "checkout.session.completed"
        handle_checkout_completed(event.data.object)
      when "customer.subscription.updated"
        handle_subscription_updated(event.data.object)
      when "customer.subscription.deleted"
        handle_subscription_deleted(event.data.object)
      when "invoice.payment_failed"
        handle_invoice_payment_failed(event.data.object)
      end

      render json: { status: "success" }

    rescue JSON::ParserError => e
      render json: { error: "Invalid payload #{e.message}" }, status: 400 and return
    rescue Stripe::SignatureVerificationError => e
      render json: { error: "Invalid signature #{e.message}" }, status: 400 and return
    rescue => e
      Rails.logger.error "❌ Unexpected Webhook Error: #{e.class} - #{e.message}"
      render json: { error: "Unexpected error: #{e.message}" }, status: 400
    end
  end

  private

  def handle_checkout_completed(session)
    customer_id = session.customer
    subscription_id = session.subscription
    return unless subscription_id.present?

    user = User.find_by(id: session.client_reference_id, stripe_customer_id: customer_id)
    Rails.logger.info "✅ Checkout completed for session.client_reference_id ##{session.client_reference_id}"
    return unless user

    subscription = Stripe::Subscription.retrieve(subscription_id)

    user.update(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status
    )

    Rails.logger.info "✅ Checkout completed for user ##{user.id} | Sub: #{subscription.id} | Status: #{subscription.status}"
  end

  def handle_subscription_updated(subscription)
    user = User.find_by(stripe_customer_id: subscription.customer)
    return unless user

    cancel_at_period_end = subscription.cancel_at_period_end
    cancel_at = subscription.cancel_at
    current_period_end = cancel_at ? Time.zone.at(cancel_at) : nil

    user.update(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status,
      cancel_at_period_end: cancel_at_period_end,
      current_period_end: current_period_end
    )

    Rails.logger.info "🔁 Subscription updated for user ##{user.id} | Status: #{subscription.status}, Ends at: #{current_period_end}"
  end

  def handle_subscription_deleted(subscription)
    user = User.find_by(stripe_subscription_id: subscription.id)
    return unless user

    user.update(
      stripe_subscription_id: nil,
      subscription_status: subscription.status,
      cancel_at_period_end: nil,
      current_period_end: nil
    )

    Rails.logger.info "❌ Subscription deleted for user ##{user.id} | Status: #{subscription.status}"
  end

  def handle_invoice_payment_failed(invoice)
    Rails.logger.info "📥 Received invoice.payment_failed: #{invoice["id"]} | subscription: #{invoice["subscription"]}"

    subscription_id = invoice["subscription"]
    user = nil
    subscription = nil

    if subscription_id.present?
      subscription = Stripe::Subscription.retrieve(subscription_id)
      user = User.find_by(stripe_subscription_id: subscription.id)
    else
      customer_id = invoice["customer"]
      Rails.logger.info "📥 Received invoice.payment_failed for customer: #{customer_id}"
      user = User.find_by(stripe_customer_id: customer_id)
    end

    return unless user

    if subscription
      user.update(subscription_status: subscription.status)
      Rails.logger.warn "⚠️ Payment failed for user ##{user.id} | Sub ID: #{subscription.id} | Status: #{subscription.status}"
    else
      Rails.logger.warn "⚠️ Payment failed for user ##{user.id} | No subscription ID available"
    end
  rescue => e
    Rails.logger.error "❌ Error handling invoice.payment_failed: #{e.message}"
  end
end
