# frozen_string_literal: true

module Books
  class KinoGridComponent < ViewComponent::Base
    def initialize(books:, books_per_shelf:, pagy: nil, next_page_path: nil)
      @books = books
      @books_per_shelf = books_per_shelf
      @pagy = pagy
      @next_page_path = next_page_path
    end
  end
end
