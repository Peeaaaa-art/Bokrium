# frozen_string_literal: true

class Books::CardGridComponent < ViewComponent::Base
  def initialize(books:, card_columns:, pagy:)
    @books = books
    @card_columns = card_columns
    @pagy = pagy
  end

  def options
    mobile? ? [ 4, 3, 6, 8, 10 ] : [ 12, 15, 18, 21, 24 ]
  end

  def default_value
    mobile? ? 4 : 12
  end

  private

  def mobile?
    helpers.mobile?
  end
end
