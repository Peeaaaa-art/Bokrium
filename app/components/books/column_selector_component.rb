# frozen_string_literal: true

module Books
  class ColumnSelectorComponent < ViewComponent::Base
    def initialize(view_key:, selected:, controller_name:, mobile: false)
      @view_key = view_key
      @selected = selected.presence || default_value_for(view_key, mobile)
      @controller_name = controller_name
      @options = options_for(view_key, mobile)
    end

    attr_reader :view_key, :selected, :options, :controller_name

    private

    def options_for(view_key, mobile)
      case view_key.to_s
      when "card"
        mobile ? [ 4, 3, 6, 8, 10 ] : [ 10, 12, 15, 18, 21, 24 ]
      when "detail_card"
        mobile ? [ 1, 2, 3 ] : [ 4, 6, 12 ]
      when "spine"
        mobile ? [ 7, 10, 14 ] : [ 14, 21, 28 ]
      else
        []
      end
    end

    def default_value_for(view_key, mobile)
      case view_key.to_s
      when "card"
        mobile ? 4 : 12
      when "detail_card"
        mobile ? 1 : 6
      when "spine"
        mobile ? 7 : 21
      else
        nil
      end
    end
  end
end
