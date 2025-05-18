class ExploreController < ApplicationController
  def index
    slice = params[:slice].to_i
    slice = 4 if slice <= 0
    @slice = slice

    @query = params[:q].to_s.strip
    @scope = params[:scope]

    @results =
      if @scope == "mine"
        search_my_books(@query)
      else
        search_public_memos(@query)
      end

    if turbo_frame_request?
      render turbo_stream: turbo_stream.update(
        "books_frame",
        partial: @scope == "mine" ? "bookshelf/kino_books_grid" : "public_bookshelf/public_card_grid",
        locals: @scope == "mine" ? { books: @results, books_per_row: @slice } : { memos: @results }
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

    Book.where(id: (title_author_ids + memo_book_ids).uniq)
  end

  def search_public_memos(query)
    scope = Memo.where(visibility: Memo::VISIBILITY[:public_site]).includes(:book, :user)

    return scope unless query.present?

    book_ids = Book.search_by_title_and_author(query).pluck(:id)
    memo_ids = scope.search_by_content(query).pluck(:id)

    scope.where(id: memo_ids).or(scope.where(book_id: book_ids))
  end
end
