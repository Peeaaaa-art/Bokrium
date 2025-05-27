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

    @books_per_shelf = session[:shelf_per]&.to_i || default_books_per_shelf
    @card_columns    = session[:card_columns]&.to_i || default_card_columns

    # ✅ Pagyを使ってページネーションする（@resultsはRelation前提）
    if @scope == "mine"
      unit_per_page = @view_mode == "shelf" ? @books_per_shelf : @card_columns
      items_per_page = (unit_per_page * 3).to_i # ← 3段くらい適当に
      @pagy, @books = pagy(@results, items: items_per_page)
    else
      @pagy, @memos = pagy(@results, items: 20)
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
        locals: if @scope == "mine"
          {
            books: @books,
            books_per_shelf: @books_per_shelf,
            card_columns: @card_columns,
            pagy: @pagy
          }
                else
          {
            memos: @memos,
            pagy: @pagy
          }
                end
      )
    else
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
