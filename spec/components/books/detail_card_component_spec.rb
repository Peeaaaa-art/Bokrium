# frozen_string_literal: true

require "rails_helper"

RSpec.describe Books::DetailCardComponent, type: :component do
  let(:books) { [] }
  let(:pagy) { double("Pagy") }
  let(:detail_card_columns) { nil }
  let(:mobile) { false }
  let(:component) { described_class.new(books: books, pagy: pagy, detail_card_columns: detail_card_columns, mobile: mobile) }

  # mobile?メソッドは@mobileパラメータではなく、helpers.mobile?を呼び出すため、
  # レンダリングコンテキストが必要。そのため、options/default_valueのテストは
  # helpers.mobile?の戻り値をスタブする必要がある
  describe "#options" do
    context "when mobile is false (desktop)" do
      let(:mobile) { false }

      it "returns desktop column options [4, 6, 12]" do
        # helpersをモック
        allow(component).to receive(:helpers).and_return(double(mobile?: false))
        expect(component.options).to eq([ 4, 6, 12 ])
      end
    end

    context "when mobile is true" do
      let(:mobile) { true }

      it "returns mobile column options [1, 2, 3]" do
        # helpersをモック
        allow(component).to receive(:helpers).and_return(double(mobile?: true))
        expect(component.options).to eq([ 1, 2, 3 ])
      end
    end
  end

  describe "#default_value" do
    context "when mobile is false (desktop)" do
      let(:mobile) { false }

      it "returns 6 as default" do
        # helpersをモック
        allow(component).to receive(:helpers).and_return(double(mobile?: false))
        expect(component.default_value).to eq(6)
      end
    end

    context "when mobile is true" do
      let(:mobile) { true }

      it "returns 1 as default" do
        # helpersをモック
        allow(component).to receive(:helpers).and_return(double(mobile?: true))
        expect(component.default_value).to eq(1)
      end
    end
  end

  describe "#col_width" do
    context "when detail_card_columns is 1" do
      let(:detail_card_columns) { 1 }

      it "returns 12 (full width)" do
        expect(component.col_width).to eq(12)
      end
    end

    context "when detail_card_columns is 2" do
      let(:detail_card_columns) { 2 }

      it "returns 6 (half width)" do
        expect(component.col_width).to eq(6)
      end
    end

    context "when detail_card_columns is 3" do
      let(:detail_card_columns) { 3 }

      it "returns 4 (one third width)" do
        expect(component.col_width).to eq(4)
      end
    end

    context "when detail_card_columns is 4" do
      let(:detail_card_columns) { 4 }

      it "returns 3 (one quarter width)" do
        expect(component.col_width).to eq(3)
      end
    end

    context "when detail_card_columns is 6" do
      let(:detail_card_columns) { 6 }

      it "returns 2 (one sixth width)" do
        expect(component.col_width).to eq(2)
      end
    end

    context "when detail_card_columns is 12" do
      let(:detail_card_columns) { 12 }

      it "returns 1 (one twelfth width)" do
        expect(component.col_width).to eq(1)
      end
    end

    context "when detail_card_columns is nil" do
      let(:detail_card_columns) { nil }

      it "returns 3 (default else case)" do
        expect(component.col_width).to eq(3)
      end
    end

    context "when detail_card_columns is an invalid value" do
      let(:detail_card_columns) { 5 }

      it "returns 3 (default else case)" do
        expect(component.col_width).to eq(3)
      end
    end

    context "when detail_card_columns is a string" do
      let(:detail_card_columns) { "6" }

      it "converts to integer and returns 2" do
        expect(component.col_width).to eq(2)
      end
    end
  end

  # レンダリングテストは省略（Deviseのwarden設定やbook_link_pathのモックが複雑になるため）
  # ビジネスロジック（col_width計算、options、default_value）のテストに集中
end
