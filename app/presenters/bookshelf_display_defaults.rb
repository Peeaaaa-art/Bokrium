# frozen_string_literal: true

module BookshelfDisplayDefaults
  def default_books_per_shelf(browser)
    case
    when browser.device.mobile? then 5
    when browser.device.tablet? then 8
    else 10
    end
  end

  def default_card_columns(mobile)
    mobile ? 4 : 12
  end

  def default_detail_card_columns(mobile)
    mobile ? 1 : 6
  end

  def default_spine_per_shelf(browser)
    case
    when browser.device.mobile? then 7
    when browser.device.tablet? then 14
    else 21
    end
  end
end
