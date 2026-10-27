require "pagy"

Pagy::OPTIONS[:items] = 50
# 他は必要になってからでOK

Rails.application.config.to_prepare do
  ApplicationController.include Pagy::Method
end
