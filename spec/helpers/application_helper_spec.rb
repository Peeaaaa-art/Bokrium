require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#nav_link_to" do
    it "現在のページと一致する場合にactiveクラスが付与されること" do
      allow(helper).to receive(:current_page?).with("/books").and_return(true)
      html = helper.nav_link_to("本棚", "/books")
      expect(html).to include("active")
      expect(html).to include("fw-semibold")
    end

    it "現在のページと一致しない場合はactiveクラスが付与されないこと" do
      allow(helper).to receive(:current_page?).with("/books").and_return(false)
      html = helper.nav_link_to("本棚", "/books")
      expect(html).not_to include("active fw-semibold")
    end
  end


  describe "#lazy_image_tag" do
    it "loading=\"lazy\" 属性が付与されること" do
      expect(helper).to receive(:image_tag).with("sample.png", hash_including(loading: "lazy"))
      helper.lazy_image_tag("sample.png")
    end
  end
end
