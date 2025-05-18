class PwaController < ApplicationController
  skip_forgery_protection only: :manifest

  def manifest
    render "manifest"
  end
end
