# frozen_string_literal: true

require "rails_helper"
require "base64"
require "fileutils"
require "json"
require "zlib"

Capybara.register_driver :playwright_webkit_bookshelf do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :webkit, headless: true,
    userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1",
    isMobile: true, hasTouch: true, deviceScaleFactor: 3)
end

RSpec.describe "Bookshelf alignment", type: :system do
  let(:user) { create(:user) }

  def cover_data(width, height, color)
    # Raster covers exercise intrinsic sizing independently of SVG's sizing rules.
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

  before do |example|
    driven_by(example.metadata[:webkit] ? :playwright_webkit_bookshelf : :playwright_chrome_headless)
    sample = "data:image/png;base64,#{Base64.strict_encode64(File.binread(Rails.root.join('spec/fixtures/files/sample.png')))}"
    covers = [ nil, cover_data(128, 200, "#4070a0"), cover_data(300, 200, "#b06b42"),
               cover_data(200, 200, "#4a8664"), sample, "data:image/png;base64,broken" ]
    24.times do |index|
      create(:book, user: user, title: "Case #{index + 1}", book_cover: covers[index % covers.length])
    end
    sign_in user
  end

  it "records shelves with placeholders, different cover ratios, and failed images" do
    FileUtils.mkdir_p(Rails.root.join("tmp/bookshelf-screenshots"))
    [ [ "mobile", 390, 5 ], [ "desktop", 1440, 10 ] ].each do |label, width, per|
      page.current_window.resize_to(width, 1600)
      visit books_path(view: "shelf", per: per)
      expect(page).to have_css(".kino-shelf-row", minimum: 2)
      expect(page).to have_css(".cover-placeholder-wrapper", minimum: 1)
      page.execute_script("document.querySelectorAll('.kino-shelf-row').forEach(row => row.getAnimations().forEach(animation => animation.finish()))")

      # Control the placeholder image without relying on the external CDN.
      placeholder_count = page.all(".placeholder-cover").size
      page.execute_script("document.querySelectorAll('.placeholder-cover').forEach(img => { img.onerror = () => img.dataset.testState = 'failed'; img.src = 'data:image/png;base64,broken'; })")
      expect(page).to have_css(".placeholder-cover[data-test-state='failed']", count: placeholder_count)
      page.save_screenshot(Rails.root.join("tmp/bookshelf-screenshots/#{label}-missing.png").to_s)
      page.execute_script("document.querySelectorAll('.placeholder-cover').forEach(img => { img.onload = () => img.dataset.testState = 'loaded'; img.src = #{cover_data(120, 180, '#e6cc55').to_json}; })")
      expect(page).to have_css(".placeholder-cover[data-test-state='loaded']", count: placeholder_count)
      page.save_screenshot(Rails.root.join("tmp/bookshelf-screenshots/#{label}-loaded.png").to_s)

      gaps = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('.kino-shelf-row')).slice(0, 2).map(row => {
          const shelf = row.querySelector('.shelf-bar').getBoundingClientRect().top;
          return Array.from(row.querySelectorAll('.book-on-shelf')).map(book => {
            const visual = book.querySelector('.cover-placeholder-wrapper') || book.querySelector('.book-cover');
            return { title: book.querySelector('img').alt, loaded: book.querySelector('img').naturalWidth > 0,
              gap: Math.round((shelf - visual.getBoundingClientRect().bottom) * 100) / 100 };
          });
        })
      JS
      puts "Bookshelf #{label} gaps (px): #{gaps.inspect}"
    end
  end
  it "records shelf alignment with WebKit and mixed cover heights", :webkit do
    sizes = [ [ 120, 170 ], [ 120, 170 ], [ 120, 170 ], [ 120, 190 ], [ 120, 170 ] ]
    user.books.order(:id).each_with_index do |book, index|
      width, height = sizes[index % sizes.length]
      data = cover_data(width, height, index % sizes.length == 3 ? "#b06b42" : "#4070a0")
      book.book_cover_s3.attach(io: StringIO.new(Base64.decode64(data.split(",").last)), filename: "cover-#{index}.png", content_type: "image/png")
    end

    # Serve attached covers through the test server, retaining the upload component markup.
    allow_any_instance_of(Book).to receive(:bokrium_cover_url) do |book|
      Rails.application.routes.url_helpers.rails_blob_path(book.book_cover_s3, only_path: true)
    end
    FileUtils.mkdir_p(Rails.root.join("tmp/bookshelf-screenshots"))
    [ [ "webkit-mobile", 390, 5 ] ].each do |label, width, per|
      page.current_window.resize_to(width, 1600)
      visit books_path(view: "shelf", per: per)
      puts "WebKit page: #{page.current_url} #{page.title} #{page.text[0, 300]}"
      expect(page).to have_css(".kino-shelf-row", minimum: 2)
      expect(page).to have_css(".book-cover", minimum: per * 2)
      page.execute_script("document.querySelectorAll('.kino-shelf-row').forEach(row => row.getAnimations().forEach(animation => animation.finish()))")
      page.execute_script(<<~JS)
        document.querySelectorAll('.book-cover').forEach(img => {
          const loaded = () => { if (img.naturalWidth > 0) img.dataset.testLoaded = 'true'; };
          img.addEventListener('load', loaded, { once: true });
          loaded();
        });
      JS
      expect(page).to have_css(".book-cover[data-test-loaded='true']", count: 24)
      page.save_screenshot(Rails.root.join("tmp/bookshelf-screenshots/#{label}.png").to_s)
      dimensions = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('.kino-shelf-row')).slice(0, 2).map(row => {
          const shelf = row.querySelector('.shelf-bar').getBoundingClientRect().top;
          return Array.from(row.querySelectorAll('.book-on-shelf')).map(book => {
            const image = book.querySelector('img');
            const link = image.parentElement;
            const rect = element => {
              const box = element.getBoundingClientRect();
              return { top: box.top, bottom: box.bottom, width: box.width, height: box.height };
            };
            return { image: rect(image), book: rect(book), link: rect(link), row: rect(row.querySelector('.book-row')),
              natural: [image.naturalWidth, image.naturalHeight], shelf: shelf,
              rowAlign: getComputedStyle(row.querySelector('.book-row')).alignItems,
              bookAlign: getComputedStyle(book).alignItems, fit: getComputedStyle(image).objectFit };
          });
        })
      JS
      puts "Bookshelf #{label} dimensions: #{dimensions.to_json}"
      page.execute_script("const style = document.createElement('style'); style.textContent = '.book-row { align-items: flex-end; }'; document.head.appendChild(style);")
      page.save_screenshot(Rails.root.join("tmp/bookshelf-screenshots/#{label}-row-aligned.png").to_s)
      aligned = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('.kino-shelf-row')).slice(0, 2).map(row => {
          const shelf = row.querySelector('.shelf-bar').getBoundingClientRect().top;
          return Array.from(row.querySelectorAll('.book-cover')).map(img => shelf - img.getBoundingClientRect().bottom);
        })
      JS
      puts "Bookshelf #{label} row-aligned gaps: #{aligned.to_json}"
    end
  end
end
