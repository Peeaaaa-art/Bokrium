class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stripe_customer

  def create
    session = Stripe::Checkout::Session.create({
      payment_method_types: [ "card" ],
      mode: "subscription",
      line_items: [ {
        price: ENV["STRIPE_PRICE_ID"],
        quantity: 1
      } ],
      success_url: root_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: root_url + "?canceled=true",
      customer: @stripe_customer_id,
      client_reference_id: current_user.id
    })
    redirect_to session.url, allow_other_host: true
  end

  def cancel
    subscription_id = current_user.stripe_subscription_id
    return redirect_to root_path, alert: "サブスクリプションが見つかりません。" if subscription_id.blank?

    Stripe::Subscription.update(
      subscription_id,
      { cancel_at_period_end: true }
    )

    subscription = Stripe::Subscription.retrieve(subscription_id)

    cancel_at_period_end = subscription.cancel_at_period_end
    cancel_at = subscription.cancel_at ? Time.zone.at(subscription.cancel_at) : nil

    current_user.update!(
      cancel_at_period_end: cancel_at_period_end,
      current_period_end: cancel_at
    )

    redirect_to root_path, notice: "サブスクリプションを解約しました。現在の請求期間終了後にキャンセルされます。"
  rescue Stripe::StripeError => e
    redirect_to root_path, alert: "エラーが発生しました: #{e.message}"
  end

  private

  def set_stripe_customer
    if current_user.stripe_customer_id.present?
      @stripe_customer_id = current_user.stripe_customer_id
    else
      email = current_user.email.presence || "guest-#{current_user.id}@bokrium.com"
      customer = Stripe::Customer.create(email: email)
      current_user.update!(stripe_customer_id: customer.id)
      @stripe_customer_id = customer.id
    end
  end
end
