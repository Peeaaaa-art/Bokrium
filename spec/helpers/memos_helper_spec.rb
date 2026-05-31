# frozen_string_literal: true

require "rails_helper"

RSpec.describe MemosHelper, type: :helper do
  describe "#render_memo_content" do
    it "renders markdown http and https links as safe anchors" do
      html = helper.render_memo_content("[公式サイト](https://example.com/path?q=1)")

      expect(html).to include('<a href="https://example.com/path?q=1"')
      expect(html).to include('target="_blank"')
      expect(html).to include('rel="noopener noreferrer nofollow ugc"')
      expect(html).to include(">公式サイト</a>")
    end

    it "does not render unsafe markdown URLs as anchors" do
      html = helper.render_memo_content("[危険](javascript:alert(1))")

      expect(html).to include("[危険](javascript:alert(1))")
      expect(html).not_to include("<a")
    end

    it "removes unsafe hrefs from raw HTML anchors" do
      html = helper.render_memo_content('<a href="javascript:alert(1)">危険</a>')

      expect(html).to include("危険")
      expect(html).not_to include("<a")
      expect(html).not_to include("javascript:")
    end

    it "removes script tags and event handlers" do
      html = helper.render_memo_content('<p onclick="alert(1)">本文</p><script>alert(1)</script>')

      expect(html).to include("<p>本文</p>")
      expect(html).not_to include("onclick")
      expect(html).not_to include("<script")
    end
  end

  describe "#render_memo_email_content" do
    it "applies compact gray inline styles to blockquotes for email clients" do
      html = helper.render_memo_email_content("<p>本文</p><blockquote><p>引用文</p></blockquote>")

      expect(html).to include("<blockquote")
      expect(html).to include("margin: 0.75em 0 0.75em 0.35em")
      expect(html).to include("padding: 0 0 0 0.35em")
      expect(html).to include("color: #777777")
      expect(html).to include("font-size: 1em")
      expect(html).to include("background-color: transparent")
    end
  end
end
