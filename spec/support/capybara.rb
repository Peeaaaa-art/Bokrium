# System テストで JavaScript（モーダル・TipTap 等）が必要な場合は
# driven_by :playwright_chrome_headless を使用する
require "capybara/rspec"
require "capybara-playwright-driver"

Capybara.register_driver :playwright_chrome_headless do |app|
  Capybara::Playwright::Driver.new(app,
    browser_type: :chromium,
    headless: true
  )
end

Capybara.server = :puma, { Silent: true }
Capybara.default_max_wait_time = 10
