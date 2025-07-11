# frozen_string_literal: true

class Books::SpineGridComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(books:, spine_per_shelf:, pagy: nil)
    @books = books
    @spine_per_shelf = spine_per_shelf
    @pagy = pagy
  end
end
