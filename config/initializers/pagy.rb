# config/initializers/pagy.rb
require "pagy"
require "pagy/extras/bootstrap"
require "pagy/extras/overflow"

Pagy::DEFAULT[:overflow] = :last_page
Pagy::DEFAULT[:items] = 50
Pagy::DEFAULT[:max_items] = nil
Pagy::DEFAULT[:limit] = 50   # ←←← これを追加！

Rails.application.config.to_prepare do
  ApplicationController.include Pagy::Backend
end
