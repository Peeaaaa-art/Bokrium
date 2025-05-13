require_relative "boot"

require "rails/all"


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bokrium
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])

    # 私が追加したもの
    config.i18n.default_locale = :ja
    config.i18n.load_path += Dir[
      Rails.root.join("config/locales/**/*.{yml}")
    ]
    config.time_zone = "Tokyo"
  end
end
