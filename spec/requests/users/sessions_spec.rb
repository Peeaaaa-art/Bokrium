# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users::Sessions", type: :request do
  describe "POST /users/sign_in" do
    it "redirects to the books index after sign in" do
      user = create(:user, password: "password123")
      create(:book, user: user)

      post user_session_path, params: {
        user: {
          email: user.email,
          password: "password123"
        }
      }

      expect(response).to redirect_to(books_path)
    end
  end
end
