module SearchHelper
  def pagination_path_for(i, search_params)
    if search_params[:title].present?
      search_books_path(type: :title, title: search_params[:title], page: i)
    elsif search_params[:author].present?
      search_books_path(type: :author, author: search_params[:author], page: i)
    else
      "#"
    end
  end
end
