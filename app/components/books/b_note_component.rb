# frozen_string_literal: true

module Books
  class BNoteComponent < ViewComponent::Base
    def initialize(books:, pagy:, next_page_path: nil)
      @books = books
      @pagy = pagy
      @next_page_path = next_page_path
    end
  end
end
