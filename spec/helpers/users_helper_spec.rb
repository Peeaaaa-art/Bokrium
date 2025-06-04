# spec/helpers/users_helper_spec.rb
require 'rails_helper'

RSpec.describe UsersHelper, type: :helper do
  describe "#user_avatar" do
    let(:user) { create(:user) }

    context "when user has an attached avatar" do
      before do
        user.avatar_s3.attach(
          io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
          filename: "sample.png", content_type: "image/png"
        )
      end

      it "returns a variant for :large size" do
        result = helper.user_avatar(user, size: :large)
        expect { result.processed }.not_to raise_error
      end
    end

    context "when user does not have an avatar" do
      it "returns correct default avatar path" do
        user_with_id_1 = build_stubbed(:user, id: 1)
        expect(helper.user_avatar(user_with_id_1)).to match(/avatar_default2.*\.png/)
      end
    end

    context "when user is nil" do
      it "returns default avatar 1" do
        expect(helper.user_avatar(nil)).to match(/avatar_default1.*\.png/)
      end
    end
  end
end
