class SubscriptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_stripe_customer

  def create
    if current_user.email.start_with?("line_user_")
      # 仮アドレス（LINEログインのみ）→ Stripe上でメール入力を促す
      session = Stripe::Checkout::Session.create({
        payment_method_types: [ "card" ],
        mode: "subscription",
        line_items: [ {
          price: ENV["STRIPE_PRICE_ID"],
          quantity: 1
        } ],
        customer_creation: "always", # Stripe側で新規入力させる
        success_url: root_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: root_url + "?canceled=true",
        client_reference_id: current_user.id
      })
    else
      # 通常メールユーザー → Stripe Customerを取得 or 作成
      monthly_support = current_user.monthly_support
      if monthly_support&.stripe_customer_id.present?
        stripe_customer_id = monthly_support.stripe_customer_id
      else
        customer = Stripe::Customer.create(email: current_user.email)
        if monthly_support
          monthly_support.update!(stripe_customer_id: customer.id)
        else
          current_user.create_monthly_support!(stripe_customer_id: customer.id)
        end
        stripe_customer_id = customer.id
      end

      session = Stripe::Checkout::Session.create({
        payment_method_types: [ "card" ],
        mode: "subscription",
        line_items: [ {
          price: ENV["STRIPE_PRICE_ID"],
          quantity: 1
        } ],
        customer: stripe_customer_id,
        success_url: root_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: root_url + "?canceled=true",
        client_reference_id: current_user.id
      })
    end

    redirect_to session.url, allow_other_host: true
  end

  def cancel
    monthly_support = current_user.monthly_support
    return redirect_to root_path, alert: "サブスクリプションが見つかりません。" if monthly_support.blank? || monthly_support.stripe_subscription_id.blank?

    subscription = Stripe::Subscription.update(
      monthly_support.stripe_subscription_id,
      { cancel_at_period_end: true }
    )

    cancel_at = subscription.cancel_at ? Time.zone.at(subscription.cancel_at) : nil

    monthly_support.update!(
      cancel_at_period_end: subscription.cancel_at_period_end,
      current_period_end: cancel_at
    )

    redirect_to root_path, notice: "これまでBokriumを支えていただき、本当にありがとうございました。サポートは現在の請求期間終了後に停止されます。"
  rescue Stripe::StripeError => e
    redirect_to root_path, alert: "エラーが発生しました: #{e.message}"
  end

  private

  def set_stripe_customer
    monthly_support = current_user.monthly_support

    if monthly_support&.stripe_customer_id.present?
      @stripe_customer_id = monthly_support.stripe_customer_id
    else
      email = current_user.email.presence || "guest-#{current_user.id}@bokrium.com"
      customer = Stripe::Customer.create(email: email)

      if monthly_support
        monthly_support.update!(stripe_customer_id: customer.id)
      else
        current_user.create_monthly_support!(stripe_customer_id: customer.id)
      end

      @stripe_customer_id = customer.id
    end
  end
end
