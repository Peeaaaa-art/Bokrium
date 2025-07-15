module Books
  class KinoSelectNumbersComponent < ViewComponent::Base
    def initialize(books_per_shelf:)
      @books_per_shelf = books_per_shelf
    end

    def options
      mobile? ? [ 5, 10 ] : [ 5, 7, 10, 12 ]
    end

    private

    def mobile?
      helpers.mobile?
    end
  end
end
