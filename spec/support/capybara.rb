# System テストで JavaScript（モーダル・TipTap 等）が必要な場合は
# driven_by :playwright_chrome_headless を使用する（Playwright は Selenium より軽量・高速）
require "capybara/rspec"
require "selenium/webdriver"
require "capybara-playwright-driver"

Capybara.register_driver :playwright_chrome_headless do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: true
  )
end

# 従来の Selenium ドライバ（必要に応じて driven_by :selenium_chrome_headless で使用）
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--disable-gpu")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1400,1400")
  options.add_argument("--disable-extensions")
  options.add_argument("--disable-features=VizDisplayCompositor")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 10
