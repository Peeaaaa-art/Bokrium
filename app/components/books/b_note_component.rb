# frozen_string_literal: true

module Books
  class BNoteComponent < ViewComponent::Base
    include Pagy::Frontend

    def initialize(books:, pagy:)
      @books = books
      @pagy = pagy
    end
  end
end
