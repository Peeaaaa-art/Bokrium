class WelcomeController < ApplicationController
  def index
    @random_memo = current_user&.memos&.includes(:book)&.order("RANDOM()")&.first
  end
end
