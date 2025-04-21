require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Bokriumm
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    # 私が追加したもの
    config.i18n.default_locale = :ja
    config.i18n.load_path += Dir[
      Rails.root.join("config/locales/**/*.{yml}")
    ]
    config.time_zone = "Tokyo"

    config.active_record.legacy_connection_handling = false
    config.active_job.queue_adapter = :async
    config.action_cable.disable_request_forgery_protection = true
  end
end
