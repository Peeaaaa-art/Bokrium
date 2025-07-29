class DonationsController < ApplicationController
  def index
  end

  def create
    amount = params[:amount].to_i
    if amount < 100
      redirect_to donations_path, alert: "100円以上でご支援をお願いします。"
      return
    end

    if current_user&.email&.start_with?("line_user_")
      # 仮メールアドレスの場合 → Stripeでメールを入力してもらう
      session = Stripe::Checkout::Session.create({
        payment_method_types: [ "card" ],
        mode: "payment",
        line_items: [ {
          price_data: {
            currency: "jpy",
            product_data: { name: "Bokriumへの寄付" },
            unit_amount: amount
          },
          quantity: 1
        } ],
        success_url: root_url + "?donation=success",
        cancel_url: root_url + "?donation=cancelled",
        customer_creation: "always",
        client_reference_id: current_user&.id
      })
    else
      # 通常メールユーザー → Stripe Customerを取得・再利用
      stripe_customer_id = nil

      if current_user.present?
        if current_user.donations.any?
          stripe_customer_id = current_user.donations.order(created_at: :desc).first&.stripe_customer_id
        end

        unless stripe_customer_id
          customer = Stripe::Customer.create(email: current_user.email)
          stripe_customer_id = customer.id
        end
      end

      session = Stripe::Checkout::Session.create({
        payment_method_types: [ "card" ],
        mode: "payment",
        line_items: [ {
          price_data: {
            currency: "jpy",
            product_data: { name: "Bokriumへの寄付" },
            unit_amount: amount
          },
          quantity: 1
        } ],
        customer: stripe_customer_id,
        success_url: root_url + "?donation=success",
        cancel_url: root_url + "?donation=cancelled",
        client_reference_id: current_user&.id
      })
    end

    redirect_to session.url, allow_other_host: true
  end

  def thank_you
    if current_user.present?
      unless current_user.monthly_support.present? || current_user.donations.exists?
        redirect_to root_path, alert: "このページにはアクセスできません。"
      end
    else
      unless session[:recent_donation]
        redirect_to root_path, alert: "このページにはアクセスできません。"
      end
    end
  end
end
