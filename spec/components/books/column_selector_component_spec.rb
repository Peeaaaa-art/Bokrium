# frozen_string_literal: true

require "rails_helper"

RSpec.describe Books::ColumnSelectorComponent, type: :component do
  let(:view_key) { "card" }
  let(:selected) { nil }
  let(:controller_name) { "column-selector" }
  let(:mobile) { false }

  subject(:component) do
    described_class.new(
      view_key: view_key,
      selected: selected,
      controller_name: controller_name,
      mobile: mobile
    )
  end

  describe "#options" do
    context "when view_key is 'card'" do
      let(:view_key) { "card" }

      context "on desktop" do
        let(:mobile) { false }

        it "returns desktop card options" do
          expect(component.options).to eq([ 10, 12, 15, 18, 21, 24 ])
        end
      end

      context "on mobile" do
        let(:mobile) { true }

        it "returns mobile card options" do
          expect(component.options).to eq([ 4, 3, 6, 8, 10 ])
        end
      end
    end

    context "when view_key is 'detail_card'" do
      let(:view_key) { "detail_card" }

      context "on desktop" do
        let(:mobile) { false }

        it "returns desktop detail_card options" do
          expect(component.options).to eq([ 4, 6, 12 ])
        end
      end

      context "on mobile" do
        let(:mobile) { true }

        it "returns mobile detail_card options" do
          expect(component.options).to eq([ 1, 2, 3 ])
        end
      end
    end

    context "when view_key is 'spine'" do
      let(:view_key) { "spine" }

      context "on desktop" do
        let(:mobile) { false }

        it "returns desktop spine options" do
          expect(component.options).to eq([ 14, 21, 28 ])
        end
      end

      context "on mobile" do
        let(:mobile) { true }

        it "returns mobile spine options" do
          expect(component.options).to eq([ 7, 10, 14 ])
        end
      end
    end

    context "when view_key is unknown" do
      let(:view_key) { "unknown" }

      it "returns empty array" do
        expect(component.options).to eq([])
      end
    end
  end

  describe "#selected" do
    context "when selected value is provided" do
      let(:selected) { 15 }

      it "uses the provided value" do
        expect(component.selected).to eq(15)
      end
    end

    context "when selected is nil" do
      let(:selected) { nil }
      let(:view_key) { "card" }
      let(:mobile) { false }

      it "uses default value" do
        expect(component.selected).to eq(12)
      end
    end

    context "when selected is empty string" do
      let(:selected) { "" }
      let(:view_key) { "detail_card" }
      let(:mobile) { true }

      it "uses default value" do
        expect(component.selected).to eq(1)
      end
    end
  end

  describe "default values" do
    let(:selected) { nil }

    context "for card view" do
      let(:view_key) { "card" }

      it "returns 12 on desktop" do
        expect(component.selected).to eq(12)
      end

      it "returns 4 on mobile" do
        component = described_class.new(
          view_key: view_key,
          selected: selected,
          controller_name: controller_name,
          mobile: true
        )
        expect(component.selected).to eq(4)
      end
    end

    context "for detail_card view" do
      let(:view_key) { "detail_card" }

      it "returns 6 on desktop" do
        expect(component.selected).to eq(6)
      end

      it "returns 1 on mobile" do
        component = described_class.new(
          view_key: view_key,
          selected: selected,
          controller_name: controller_name,
          mobile: true
        )
        expect(component.selected).to eq(1)
      end
    end

    context "for spine view" do
      let(:view_key) { "spine" }

      it "returns 21 on desktop" do
        expect(component.selected).to eq(21)
      end

      it "returns 7 on mobile" do
        component = described_class.new(
          view_key: view_key,
          selected: selected,
          controller_name: controller_name,
          mobile: true
        )
        expect(component.selected).to eq(7)
      end
    end

    context "for unknown view" do
      let(:view_key) { "unknown" }

      it "returns nil" do
        expect(component.selected).to be_nil
      end
    end
  end

  describe "rendering" do
    let(:view_key) { "card" }
    let(:selected) { 15 }

    before do
      allow_any_instance_of(described_class).to receive(:helpers).and_return(
        double("Helpers", books_index_path: "/books")
      )
    end

    it "renders the select tag with correct options" do
      render_inline(component)

      expect(page).to have_select("column", options: [ "10", "12", "15", "18", "21", "24" ])
    end

    it "selects the specified value" do
      render_inline(component)

      expect(page).to have_select("column", selected: "15")
    end

    it "renders hidden fields with correct values" do
      render_inline(component)

      expect(page).to have_field("view", type: "hidden", with: "card")
      expect(page).to have_field("column", type: "hidden", with: "15")
    end

    it "renders with correct data controller" do
      render_inline(component)

      expect(page).to have_css("[data-controller='column-selector']")
    end
  end
end
