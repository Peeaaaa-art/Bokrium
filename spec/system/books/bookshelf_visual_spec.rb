# frozen_string_literal: true

require "rails_helper"
require "base64"
require "fileutils"
require "zlib"

Capybara.register_driver :playwright_webkit_bookshelf do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :webkit, headless: true,
    userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1",
    isMobile: true, hasTouch: true, deviceScaleFactor: 3)
end

RSpec.describe "Bookshelf alignment", type: :system do
  let(:user) { create(:user) }

  def cover_data(width, height, color)
    # Solid PNGs keep cover boundaries measurable without external image services.
    chunk = lambda do |type, data|
      [ data.bytesize ].pack("N") + type + data + [ Zlib.crc32(type + data) ].pack("N")
    end
    pixel = [ color.delete_prefix("#") ].pack("H*")
    raw = ("\x00".b + pixel * width) * height
    png = "\x89PNG\r\n\x1a\n".b
    png += chunk.call("IHDR", [ width, height, 8, 2, 0, 0, 0 ].pack("NNC5"))
    png += chunk.call("IDAT", Zlib::Deflate.deflate(raw))
    png += chunk.call("IEND", "".b)
    "data:image/png;base64,#{Base64.strict_encode64(png)}"
  end

  def finish_book_transitions
    page.execute_script("document.querySelectorAll('.book-on-shelf').forEach(book => book.getAnimations().forEach(animation => animation.finish()))")
  end

  def shelf_gaps
    page.evaluate_script(<<~JS)
      Array.from(document.querySelectorAll('.kino-shelf-row')).map(row => {
        const shelf = row.querySelector('.shelf-bar').getBoundingClientRect().top;
        return Array.from(row.querySelectorAll('.book-cover')).map(img => shelf - img.getBoundingClientRect().bottom);
      })
    JS
  end

  before do |example|
    driven_by(example.metadata[:webkit] ? :playwright_webkit_bookshelf : :playwright_chrome_headless)
    # The first row matches the report: four shorter covers and one taller cover.
    sizes = [ [ 120, 170 ], [ 120, 170 ], [ 120, 170 ], [ 120, 190 ], [ 120, 170 ],
              [ 200, 200 ], [ 300, 200 ], [ 120, 180 ], [ 120, 190 ], [ 120, 170 ] ]
    20.times do |index|
      width, height = sizes[index % sizes.length]
      color = index.even? ? "#4070a0" : "#b06b42"
      data = cover_data(width, height, color)
      book = create(:book, user: user, title: "Visual book #{index + 1}", created_at: Time.current - index.minutes, book_cover: data)
      if index.even?
        book.book_cover_s3.attach(io: StringIO.new(Base64.decode64(data.split(",").last)),
          filename: "cover-#{index}.png", content_type: "image/png")
      end
    end
    allow_any_instance_of(Book).to receive(:bokrium_cover_url) do |book|
      Rails.application.routes.url_helpers.rails_blob_path(book.book_cover_s3, only_path: true)
    end
    sign_in user
  end

  [ [ "chromium-mobile", 390, 5, false ], [ "chromium-desktop", 1440, 10, false ],
    [ "webkit-mobile", 390, 5, true ] ].each do |label, width, per, webkit|
    it "keeps mixed-height covers on every shelf in #{label}", webkit: webkit do
      page.current_window.resize_to(width, 1600)
      visit books_path(view: "shelf", per: per)
      expect(page).to have_css(".kino-shelf-row", minimum: 2)
      expect(page).to have_css(".book-cover", count: 20)
      page.execute_script(<<~JS)
        document.querySelectorAll('.book-cover').forEach(img => {
          const markLoaded = () => { if (img.naturalWidth > 0) img.dataset.testLoaded = 'true'; };
          img.addEventListener('load', markLoaded, { once: true });
          img.loading = 'eager';
          markLoaded();
        });
        document.querySelectorAll('.kino-shelf-row').forEach(row => row.getAnimations().forEach(animation => animation.finish()));
      JS
      expect(page).to have_css(".book-cover[data-test-loaded='true']", count: 20)
      FileUtils.mkdir_p(Rails.root.join("tmp/bookshelf-screenshots"))
      page.save_screenshot(Rails.root.join("tmp/bookshelf-screenshots/#{label}.png").to_s)

      # Allow subpixel rounding and the existing slight overlap with the shelf.
      expect(shelf_gaps.flatten).to all(be_between(-2, 2))

      if webkit
        # Keep the page open so the persistent touch hover can be inspected.
        page.execute_script("document.querySelector('.book-on-shelf a').addEventListener('click', event => event.preventDefault(), { once: true })")
        page.driver.with_playwright_page { |browser_page| browser_page.tap_point(".book-on-shelf a") }
        finish_book_transitions
        page.save_screenshot(Rails.root.join("tmp/bookshelf-screenshots/#{label}-after-tap.png").to_s)
        expect(shelf_gaps.flatten).to all(be_between(-2, 2))
      elsif label == "chromium-desktop"
        page.first(".book-on-shelf").hover
        finish_book_transitions
        # Mouse users retain the existing hover lift.
        expect(shelf_gaps.first.first).to be > 2
      end
    end
  end
end
