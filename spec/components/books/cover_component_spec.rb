# frozen_string_literal: true

require "rails_helper"

RSpec.describe Books::CoverComponent, type: :component do
  let(:book_cover_url) { nil }
  let(:book) { build(:book, title: "テスト書籍", book_cover: book_cover_url) }
  let(:alt) { nil }
  let(:image_class) { "" }
  let(:s3_class) { "s3-specific" }
  let(:url_class) { "url-specific" }
  let(:no_cover_class) { "no-cover-specific" }
  let(:truncate_options) { {} }
  let(:options) { {} }

  subject(:component) do
    described_class.new(
      book: book,
      alt: alt,
      image_class: image_class,
      s3_class: s3_class,
      url_class: url_class,
      no_cover_class: no_cover_class,
      truncate_options: truncate_options,
      **options
    )
  end

  before do
    allow_any_instance_of(described_class).to receive(:helpers).and_return(
      double("Helpers",
             cdn_path: "https://cdn.example.com/no_cover.png",
             truncate_for_device: "テスト書籍")
    )
  end

  describe "#show_s3_cover?" do
    context "when S3 cover is attached and has a key" do
      before do
        blob_double = double("Blob", key: "some-key")
        attached_double = double("Attached", attached?: true, key: "some-key", blob: blob_double)
        allow(book).to receive(:book_cover_s3).and_return(attached_double)
      end

      it "returns true" do
        expect(component.show_s3_cover?).to be true
      end
    end

    context "when S3 cover is not attached" do
      before do
        attached_double = double("Attached", attached?: false)
        allow(book).to receive(:book_cover_s3).and_return(attached_double)
      end

      it "returns false" do
        expect(component.show_s3_cover?).to be false
      end
    end

    context "when S3 cover is attached but has no key" do
      before do
        attached_double = double("Attached", attached?: true, key: nil)
        allow(book).to receive(:book_cover_s3).and_return(attached_double)
      end

      it "returns false" do
        expect(component.show_s3_cover?).to be false
      end
    end
  end

  describe "#show_url_cover?" do
    context "when book_cover URL is present" do
      let(:book_cover_url) { "https://example.com/cover.jpg" }

      it "returns true" do
        expect(component.show_url_cover?).to be true
      end
    end

    context "when book_cover URL is blank" do
      let(:book_cover_url) { "" }

      it "returns false" do
        expect(component.show_url_cover?).to be false
      end
    end

    context "when book_cover URL is nil" do
      let(:book_cover_url) { nil }

      it "returns false" do
        expect(component.show_url_cover?).to be false
      end
    end
  end

  describe "#bokrium_cover_url" do
    it "delegates to book model" do
      allow(book).to receive(:bokrium_cover_url).and_return("https://cdn.bokrium.com/image.jpg")

      expect(component.bokrium_cover_url).to eq("https://cdn.bokrium.com/image.jpg")
    end
  end

  describe "#title_for_overlay" do
    it "calls helpers.truncate_for_device with book title and truncate_options" do
      truncate_opts = { length: 20 }
      component = described_class.new(
        book: book,
        truncate_options: truncate_opts
      )

      helpers_mock = double("Helpers")
      allow(component).to receive(:helpers).and_return(helpers_mock)
      expect(helpers_mock).to receive(:truncate_for_device).with("テスト書籍", truncate_opts)

      component.title_for_overlay
    end
  end

  describe "initialization" do
    context "when alt is provided" do
      let(:alt) { "カスタムALT" }

      it "uses the provided alt text" do
        expect(component.instance_variable_get(:@alt)).to eq("カスタムALT")
      end
    end

    context "when alt is not provided and book has title" do
      let(:book) { build(:book, title: "書籍タイトル") }

      it "uses book title as alt text" do
        expect(component.instance_variable_get(:@alt)).to eq("書籍タイトル")
      end
    end

    context "when alt is not provided and book title is blank" do
      let(:book) { build(:book, title: nil) }

      it "uses default alt text" do
        expect(component.instance_variable_get(:@alt)).to eq("表紙画像")
      end
    end
  end

  describe "rendering" do
    context "with S3 cover" do
      before do
        blob_double = double("Blob", key: "test-key")
        attached_double = double("Attached", attached?: true, key: "test-key", blob: blob_double)
        allow(book).to receive(:book_cover_s3).and_return(attached_double)
        allow(book).to receive(:bokrium_cover_url).and_return("https://cdn.bokrium.com/test.jpg")
      end

      it "renders S3 image with correct classes" do
        render_inline(component)

        expect(page).to have_css("img[src='https://cdn.bokrium.com/test.jpg']")
        expect(page).to have_css("img.s3-specific")
        expect(page).to have_css("img.img-fluid")
        expect(page).not_to have_css(".url-specific")
        expect(page).not_to have_css(".no-cover-specific")
      end

      it "renders with correct alt text" do
        render_inline(component)

        expect(page).to have_css("img[alt='テスト書籍']")
      end

      it "renders with lazy loading" do
        render_inline(component)

        expect(page).to have_css("img[loading='lazy']")
      end
    end

    context "with URL cover only (no S3)" do
      let(:book_cover_url) { "https://example.com/book.jpg" }

      before do
        attached_double = double("Attached", attached?: false)
        allow(book).to receive(:book_cover_s3).and_return(attached_double)
      end

      it "renders URL image with correct classes" do
        render_inline(component)

        expect(page).to have_css("img[src='https://example.com/book.jpg']")
        expect(page).to have_css("img.url-specific")
        expect(page).to have_css("img.img-fluid")
        expect(page).not_to have_css(".s3-specific")
        expect(page).not_to have_css(".no-cover-specific")
      end
    end

    context "with no cover (fallback)" do
      let(:book_cover_url) { nil }

      before do
        attached_double = double("Attached", attached?: false)
        allow(book).to receive(:book_cover_s3).and_return(attached_double)
      end

      it "renders placeholder with no_cover.png" do
        render_inline(component)

        expect(page).to have_css("img[src='https://cdn.example.com/no_cover.png']")
        expect(page).to have_css(".cover-placeholder-wrapper")
      end

      it "renders title overlay" do
        render_inline(component)

        expect(page).to have_css(".cover-title-overlay", text: "テスト書籍")
      end

      it "renders Bokrium logo overlay" do
        render_inline(component)

        expect(page).to have_css(".logo-overlay", text: "Bokrium")
      end

      it "applies no_cover_class" do
        render_inline(component)

        expect(page).to have_css("img.no-cover-specific")
        expect(page).to have_css("img.placeholder-cover")
      end
    end

    context "with custom image_class" do
      let(:image_class) { "custom-class another-class" }
      let(:book_cover_url) { nil }

      before do
        attached_double = double("Attached", attached?: false)
        allow(book).to receive(:book_cover_s3).and_return(attached_double)
      end

      it "applies custom classes to all image types" do
        render_inline(component)

        expect(page).to have_css("img.custom-class.another-class")
      end
    end

    context "with additional options" do
      let(:options) { { width: "200", height: "300", data: { test: "value" } } }
      let(:book_cover_url) { nil }

      before do
        attached_double = double("Attached", attached?: false)
        allow(book).to receive(:book_cover_s3).and_return(attached_double)
      end

      it "merges options into image tag" do
        render_inline(component)

        expect(page).to have_css("img[width='200']")
        # Note: height: "auto" is set in the template, so it overrides the option
        expect(page).to have_css("img[data-test='value']")
      end
    end
  end

  describe "display priority" do
    context "when both S3 and URL covers exist" do
      let(:book_cover_url) { "https://example.com/url-cover.jpg" }

      before do
        blob_double = double("Blob", key: "s3-key")
        attached_double = double("Attached", attached?: true, key: "s3-key", blob: blob_double)
        allow(book).to receive(:book_cover_s3).and_return(attached_double)
        allow(book).to receive(:bokrium_cover_url).and_return("https://cdn.bokrium.com/s3-cover.jpg")
      end

      it "prioritizes S3 cover over URL cover" do
        render_inline(component)

        expect(page).to have_css("img[src='https://cdn.bokrium.com/s3-cover.jpg']")
        expect(page).not_to have_css("img[src='https://example.com/url-cover.jpg']")
        expect(page).to have_css(".s3-specific")
        expect(page).not_to have_css(".url-specific")
      end
    end
  end
end
