class SubscriptionsController < ApplicationController
  def create
    session = Stripe::Checkout::Session.create({
      payment_method_types: [ "card" ],
      mode: "subscription",
      line_items: [ {
        price: ENV["STRIPE_PRICE_ID"],
        quantity: 1
      } ],
      success_url: root_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: root_url + "?canceled=true"
    })
    redirect_to session.url, allow_other_host: true
  end
end
