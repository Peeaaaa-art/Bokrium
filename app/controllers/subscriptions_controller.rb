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
      customer: @stripe_customer_id
    })
    redirect_to session.url, allow_other_host: true
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
