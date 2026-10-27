# frozen_string_literal: true

require "rails_helper"
require "base64"
require "fileutils"
require "json"

Capybara.register_driver :playwright_webkit_bookshelf do |app|
  Capybara::Playwright::Driver.new(app, browser_type: :webkit, headless: true,
    userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
    isMobile: true, hasTouch: true, deviceScaleFactor: 3)
end

RSpec.describe "Bookshelf alignment", type: :system do
  let(:user) { create(:user) }

  def cover_data(width, height, color)
    svg = %(<svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}"><rect width="100%" height="100%" fill="#{color}"/></svg>)
    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end

  before do
    driven_by :playwright_chrome_headless
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
      page.execute_script("document.getAnimations().forEach(animation => animation.finish())")

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
  it "records shelf alignment with WebKit and mixed cover heights" do
    driven_by :playwright_webkit_bookshelf
    sizes = [ [ 120, 170 ], [ 120, 170 ], [ 120, 170 ], [ 120, 190 ], [ 120, 170 ] ]
    user.books.order(:id).each_with_index do |book, index|
      width, height = sizes[index % sizes.length]
      book.update!(book_cover: cover_data(width, height, index % sizes.length == 3 ? "#b06b42" : "#4070a0"))
    end

    FileUtils.mkdir_p(Rails.root.join("tmp/bookshelf-screenshots"))
    [ [ "webkit-mobile", 390, 5 ] ].each do |label, width, per|
      page.current_window.resize_to(width, 1600)
      visit books_path(view: "shelf", per: per)
      expect(page).to have_css(".kino-shelf-row", minimum: 2)
      expect(page).to have_css(".book-cover", minimum: per * 2)
      page.execute_script("document.getAnimations().forEach(animation => animation.finish())")
      expect(page.evaluate_script("Array.from(document.querySelectorAll('.book-cover')).every(img => img.complete && img.naturalWidth > 0)")).to eq(true)
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
    end
  end

end
