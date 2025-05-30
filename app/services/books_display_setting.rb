# frozen_string_literal: true

class BooksDisplaySetting
  VIEW_MODE_KEY      = :view_mode
  SHELF_PER_KEY      = :shelf_per
  CARD_COLUMNS_KEY   = :card_columns

  attr_reader :view_mode, :unit_per_page, :books_per_shelf, :card_columns

  def initialize(session, params, defaults)
    @session = session
    @params = params
    @defaults = defaults

    configure_view_mode
    configure_unit_per_page
  end

  private

  def configure_view_mode
    @session[VIEW_MODE_KEY] = @params[:view] if @params[:view].present?
    @view_mode = @session[VIEW_MODE_KEY] || "shelf"
  end

  def configure_unit_per_page
    case @view_mode
    when "shelf"
      @session[SHELF_PER_KEY] = @params[:per] if @params[:per].present?
      @books_per_shelf = @session[SHELF_PER_KEY]&.to_i || @defaults[:shelf]
      @unit_per_page = @books_per_shelf
    when "card"
      @session[CARD_COLUMNS_KEY] = @params[:column] if @params[:column].present?
      @card_columns = @session[CARD_COLUMNS_KEY]&.to_i || @defaults[:card]
      @unit_per_page = @card_columns
    else
      @unit_per_page = @defaults[:shelf]
    end
  end
end
