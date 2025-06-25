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
      when "customer.subscription.created"
        handle_subscription_created(event.data.object)
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
    mode = session.mode # "payment" または "subscription"
    customer_id = session.customer
    user_id = session.client_reference_id

    user = User.find_by(id: user_id) if user_id.present?

    if mode == "subscription"
      return unless user

      unless user.monthly_support
        user.create_monthly_support!(
          stripe_customer_id: customer_id
        )
      end

      Rails.logger.info "✅ [Subscription] Checkout completed for user ##{user.id} | Customer ID: #{customer_id}"

    elsif mode == "payment"
      amount = session.amount_total || session.display_items&.first&.amount || 0

      if user
        user.donations.create!(
          stripe_payment_intent_id: session.payment_intent,
          stripe_checkout_session_id: session.id,
          amount: amount,
          customer_id: customer_id,
          status: "succeeded"
        )

        Rails.logger.info "🎁 [Donation] One-time donation from user ##{user.id} | ¥#{amount / 100} JPY"
      else
        Rails.logger.info "🎁 [Donation] One-time anonymous donation | Customer ID: #{customer_id} | ¥#{amount / 100} JPY"
      end
    end
  end

  def handle_subscription_created(subscription)
    customer_id = subscription.customer
    monthly_support = MonthlySupport.find_by(stripe_customer_id: customer_id)
    return unless monthly_support

    monthly_support.update!(
      stripe_subscription_id: subscription.id,
      subscription_status: subscription.status,
    )

    Rails.logger.info "🎉 Subscription created for user ##{monthly_support.user_id} | Sub ID: #{subscription.id}"
  end

  def handle_subscription_updated(subscription)
    monthly_support = MonthlySupport.find_by(stripe_subscription_id: subscription.id)
    return unless monthly_support

    cancel_at = subscription.cancel_at
    monthly_support.update(
      subscription_status: subscription.status,
      cancel_at_period_end: subscription.cancel_at_period_end,
      current_period_end: cancel_at ? Time.zone.at(cancel_at) : nil
    )

    Rails.logger.info "🔁 Subscription updated for user ##{monthly_support.user_id} | Status: #{subscription.status}"
  end

  def handle_subscription_deleted(subscription)
    monthly_support = MonthlySupport.find_by(stripe_subscription_id: subscription.id)
    return unless monthly_support

    monthly_support.update(
      stripe_subscription_id: nil,
      subscription_status: subscription.status,
      cancel_at_period_end: nil,
      current_period_end: nil
    )

    Rails.logger.info "❌ Subscription deleted for user ##{monthly_support.user_id}"
  end

  def handle_invoice_payment_failed(invoice)
    subscription_id = invoice["subscription"]
    monthly_support = nil
    subscription = nil

    if subscription_id.present?
      monthly_support = MonthlySupport.find_by(stripe_subscription_id: subscription_id)
      subscription = Stripe::Subscription.retrieve(subscription_id)
    else
      customer_id = invoice["customer"]
      monthly_support = MonthlySupport.find_by(stripe_customer_id: customer_id)
    end

    return unless monthly_support

    if subscription
      monthly_support.update(subscription_status: subscription.status)
      Rails.logger.warn "⚠️ Payment failed for user ##{monthly_support.user_id} | Sub ID: #{subscription.id} | Status: #{subscription.status}"
    else
      Rails.logger.warn "⚠️ Payment failed for user ##{monthly_support.user_id} | No subscription ID available"
    end
  rescue => e
    Rails.logger.error "❌ Error handling invoice.payment_failed: #{e.message}"
  end
end
