# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Devise initializer" do
  it "keeps remember me cookies for one month and extends them on access" do
    expect(Devise.remember_for).to eq(1.month)
    expect(Devise.extend_remember_period).to be(true)
  end
end
