# frozen_string_literal: true

module Books
  class DetailCardComponent < ViewComponent::Base
    def initialize(books:, pagy:, detail_card_columns: nil, mobile: false)
      @books = books
      @pagy = pagy
      @detail_card_columns = detail_card_columns
      @mobile = mobile
    end

    def options
      mobile? ? [ 1, 2, 3 ] : [ 4, 6, 12 ]
    end

    def default_value
      mobile? ? 1 : 6
    end

    def col_width
      case @detail_card_columns.to_i
      when 1 then 12
      when 2 then 6
      when 3 then 4
      when 4 then 3
      when 6 then 2
      when 12 then 1
      else 3
      end
    end

      private

    def mobile?
      helpers.mobile?
    end
  end
end
