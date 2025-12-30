require "pagy"

Pagy.options[:items] = 50
# 他は必要になってからでOK

Rails.application.config.to_prepare do
  ApplicationController.include Pagy::Method
end