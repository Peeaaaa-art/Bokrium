# frozen_string_literal: true

class BooksDisplaySetting
  VIEW_MODE_KEY           = :view_mode
  SHELF_PER_KEY           = :shelf_per
  CARD_COLUMNS_KEY        = :card_columns
  DETAIL_CARD_COLUMNS_KEY = :detail_card_columns
  SPINE_PER_KEY           = :spine_per

  attr_reader :view_mode, :unit_per_page, :books_per_shelf,
              :card_columns, :detail_card_columns, :spine_per_shelf

  def initialize(session, params, defaults, mobile: false)
    @session = session
    @params = params
    @defaults = defaults
    @mobile = mobile

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
    when "detail_card"
      @session[DETAIL_CARD_COLUMNS_KEY] = @params[:column] if @params[:column].present?
      @detail_card_columns = @session[DETAIL_CARD_COLUMNS_KEY]&.to_i || @defaults[:detail_card]
      @unit_per_page = @mobile ? @detail_card_columns * 4 : @detail_card_columns
    when "b_note"
      @unit_per_page = 7.2
    when "spine"
      @session[SPINE_PER_KEY] = @params[:per_spine] if @params[:per_spine].present?
      @spine_per_shelf = @session[SPINE_PER_KEY]&.to_i || @defaults[:spine]
      @unit_per_page = @spine_per_shelf

    else
      @unit_per_page = @defaults[:shelf]

    end
  end
end
