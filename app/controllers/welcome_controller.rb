class WelcomeController < ApplicationController
  def index
    @random_memo = current_user&.memos&.includes(:book)&.random_1
  end
end
