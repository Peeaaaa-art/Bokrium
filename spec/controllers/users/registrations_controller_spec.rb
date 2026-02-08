# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::RegistrationsController, type: :controller do
  include Devise::Test::ControllerHelpers

  # development? true の例では path 文字列比較のため double で十分。false の例では super が Devise のマッピング解決をするため User が必要
  let(:resource) { build(:user) }

  before do
    # リクエストをセットアップし、super 呼び出し時のパス解決を可能にする
    request.env["devise.mapping"] = Devise.mappings[:user]
    get :new
  end

  after(:each) do
    allow(Rails.env).to receive(:development?).and_call_original
  end

  describe "#after_inactive_sign_up_path_for" do
    context "when Rails.env.development? is true" do
      before { allow(Rails.env).to receive(:development?).and_return(true) }

      it "returns the confirmation pending path (development 用 letter_opener リンク先)" do
        result = controller.send(:after_inactive_sign_up_path_for, resource)

        # routes は test では development でないため user_confirmation_pending が定義されないのでパス文字列で比較
        expect(result).to eq("/users/confirmation_pending")
      end
    end

    context "when Rails.env.development? is false" do
      before { allow(Rails.env).to receive(:development?).and_return(false) }

      it "returns the same path as the superclass (Devise default)" do
        result = controller.send(:after_inactive_sign_up_path_for, resource)

        # この環境では super (Devise) が root パスを返す
        expect(result).to eq("/")
      end
    end
  end
end
