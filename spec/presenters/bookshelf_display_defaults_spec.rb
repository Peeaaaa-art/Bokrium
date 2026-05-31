# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookshelfDisplayDefaults do
  subject(:defaults) do
    Class.new do
      include BookshelfDisplayDefaults
    end.new
  end

  describe "#default_spine_per_shelf" do
    it "uses one fewer spine book for tablet-sized devices" do
      browser = double("browser", device: double("device", mobile?: false, tablet?: true))

      expect(defaults.default_spine_per_shelf(browser)).to eq(13)
    end
  end
end
