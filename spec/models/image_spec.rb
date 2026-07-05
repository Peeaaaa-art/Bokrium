require 'rails_helper'

RSpec.describe Image, type: :model do
  describe "アップロード形式のバリデーション" do
    it "PNGは許可される" do
      image = FactoryBot.build(:image)
      expect(image).to be_valid
    end

    it "SVGは拒否される(stored XSSベクタ)" do
      image = FactoryBot.build(:image)
      image.image_s3.attach(
        io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"><script>alert(1)</script></svg>'),
        filename: "evil.svg",
        content_type: "image/svg+xml"
      )
      expect(image).not_to be_valid
      expect(image.errors[:image_s3].join).to include("許可されていない形式")
    end

    it "content_typeをimage/pngと偽装したSVGも拒否される" do
      image = FactoryBot.build(:image)
      image.image_s3.attach(
        io: StringIO.new("<svg/>"),
        filename: "evil.svg",
        content_type: "image/png"
      )
      expect(image).not_to be_valid
      expect(image.errors[:image_s3]).to be_present
    end
  end
end
