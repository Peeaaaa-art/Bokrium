# frozen_string_literal: true

require "rails_helper"
require "base64"
require "fileutils"

RSpec.describe "Bookshelf alignment", type: :system do
  let(:user) { create(:user) }

  before do
    driven_by :playwright_chrome_headless
    # Local, deterministic covers of different proportions avoid external image services.
    20.times do |index|
      width, height = index.even? ? [ 120, 180 ] : [ 180, 120 ]
      color = index.even? ? "#4070a0" : "#b06b42"
      svg = %(<svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="#{height}"><rect width="100%" height="100%" fill="#{color}"/><text x="10" y="30" fill="white">Book #{index + 1}</text></svg>)
      create(:book, user: user, title: "Visual book #{index + 1}", book_cover: "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}")
    end
    sign_in user
  end

  it "records mobile and desktop shelves with multiple rows and cover sizes" do
    FileUtils.mkdir_p(Rails.root.join("tmp/bookshelf-screenshots"))
    [ [ "mobile", 390, 5 ], [ "desktop", 1440, 10 ] ].each do |label, width, per|
      page.current_window.resize_to(width, 1600)
      visit books_path(view: "shelf", per: per)
      expect(page).to have_css(".kino-shelf-row", minimum: 2)
      expect(page).to have_css(".book-cover", minimum: per * 2)
      page.execute_script("document.getAnimations().forEach(animation => animation.finish())")
      page.save_screenshot(Rails.root.join("tmp/bookshelf-screenshots/#{label}.png").to_s)
      gaps = page.evaluate_script(<<~JS)
        Array.from(document.querySelectorAll('.kino-shelf-row')).slice(0, 2).map(row => {
          const shelf = row.querySelector('.shelf-bar').getBoundingClientRect().top;
          return Array.from(row.querySelectorAll('.book-cover')).map(cover =>
            Math.round((shelf - cover.getBoundingClientRect().bottom) * 100) / 100);
        })
      JS
      puts "Bookshelf #{label} gaps (px): #{gaps.inspect}"
    end
  end
end
