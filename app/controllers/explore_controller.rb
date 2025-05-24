class ExploreController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @scope = params[:scope]

    uri = URI.parse(request.referer || "")
    view_mode_from_ref = Rack::Utils.parse_nested_query(uri.query)["view"]
    @view_mode = view_mode_from_ref.presence_in(%w[shelf card]) || "shelf"

    @results =
      if @scope == "mine"
        search_my_books(@query)
      else
        search_public_memos(@query)
      end

    browser = Browser.new(request.user_agent)
    device_type = browser.device

    @books_per_row = case
    when device_type.mobile? then 5
    when device_type.tablet? then 8
    else 10
    end


    if turbo_frame_request?
      partial_name =
        if @scope == "mine"
          @view_mode == "shelf" ? "bookshelf/kino_books_grid" : "bookshelf/simple_card"
        else
          "public_bookshelf/public_card"
        end

      render turbo_stream: turbo_stream.update(
        "books_frame",
        partial: partial_name,
        locals: @scope == "mine" ?
          { books: @results, books_per_row: @books_per_row } :
          { memos: @results }
      )
    else
      @books = @results if @scope == "mine"
      @memos = @results unless @scope == "mine"
      render :index
    end
  end

  private

  def search_my_books(query)
    return Book.none unless user_signed_in?

    books = current_user.books.includes(:memos)
    return books unless query.present?

    title_author_ids = books.search_by_title_and_author(query).pluck(:id)
    memo_book_ids = current_user.memos.search_by_content(query).pluck(:book_id)

    current_user.books.where(id: (title_author_ids + memo_book_ids).uniq)
  end

  def search_public_memos(query)
    scope = Memo.where(visibility: Memo::VISIBILITY[:public_site]).includes(:book, :user)

    return scope unless query.present?

    book_ids = Book.search_by_title_and_author(query).pluck(:id)
    memo_ids = scope.search_by_content(query).pluck(:id)

    scope.where(id: memo_ids).or(scope.where(book_id: book_ids))
  end
end
