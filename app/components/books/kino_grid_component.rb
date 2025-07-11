# frozen_string_literal: true

module Books
  class KinoGridComponent < ViewComponent::Base
    def initialize(books:, books_per_shelf:, pagy: nil)
      @books = books
      @books_per_shelf = books_per_shelf
      @pagy = pagy
    end
  end
end
