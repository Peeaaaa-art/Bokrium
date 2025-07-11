# frozen_string_literal: true

module Books
  class FrameWrapperComponent < ViewComponent::Base
    def initialize(
      books:,
      pagy:,
      view_mode:,
      books_per_shelf:,
      card_columns:,
      detail_card_columns:,
      spine_per_shelf:,
      read_only: false
    )
      @books = books
      @pagy = pagy
      @view_mode = view_mode
      @books_per_shelf = books_per_shelf
      @card_columns = card_columns
      @detail_card_columns = detail_card_columns
      @spine_per_shelf = spine_per_shelf
      @read_only = read_only
    end
  end
end
