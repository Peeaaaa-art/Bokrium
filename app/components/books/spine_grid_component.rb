# frozen_string_literal: true

class Books::SpineGridComponent < ViewComponent::Base
  include ApplicationHelper

  def initialize(books:, spine_per_shelf:, pagy: nil, next_page_path: nil)
    @books = books
    @spine_per_shelf = spine_per_shelf
    @pagy = pagy
    @next_page_path = next_page_path
  end
end
