class PwaController < ApplicationController
  skip_forgery_protection only: :manifest

  def manifest
    render "pwa/manifest", formats: :json
  end
end
