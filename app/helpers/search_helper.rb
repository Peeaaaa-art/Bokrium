module SearchHelper
  def pagination_path_for(i, search_params)
    if search_params[:query].present? && search_params[:type].present?
      search_books_path(
        type: search_params[:type],
        query: search_params[:query],
        engine: search_params[:engine], # これも保持するとより安全
        page: i
      )
    else
      "#"
    end
  end

  def search_result_range(books, total_count, per_page: 30)
    current_page = (params[:page] || 1).to_i
    start_num = (current_page - 1) * per_page + 1
    end_num = start_num + books.size - 1

    "（#{number_with_delimiter(total_count)}件中 #{number_with_delimiter(start_num)}〜#{number_with_delimiter(end_num)}件目を表示）"
  end

  def placeholder_for(type)
    key = type.presence || "title"
    I18n.t("placeholders.#{key}", default: I18n.t("placeholders.default"))
  end
end
