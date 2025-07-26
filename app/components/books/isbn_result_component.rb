module Books
  class IsbnResultComponent < ViewComponent::Base
    TITLE_TRUNCATE_LIMIT = 30

    def initialize(book_data:)
      @book = book_data.with_indifferent_access
    end

    def logged_in?
      helpers.user_signed_in?
    end
  end
end
