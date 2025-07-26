# frozen_string_literal: true

module Books
  class KinoSelectNumbersComponent < ViewComponent::Base
    def initialize(view_key:, selected:, mobile:)
      @view_key = view_key.to_s
      @selected = selected
      @mobile = mobile
    end

    def options
      case @view_key
      when "shelf"
        @mobile ? [ 5, 10 ] : [ 7, 10, 12 ]
      when "spine"
        @mobile ? [ 7, 14 ] : [ 14, 21, 28, 35 ]
      else
        []
      end
    end

    def per_param_name
      @view_key == "spine" ? :per_spine : :per
    end
  end
end
