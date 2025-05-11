class ExploreController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @scope = params[:scope]

    @results =
      if @scope == "mine"
        search_my_books(@query)
      else
        search_public_books(@query)
      end
  end

  private

  def search_my_books(query)
    return Book.none unless user_signed_in?

    books = current_user.books.includes(:memos)

    return books unless query.present?

    # 検索条件に一致する book_id をすべて集めて結合
    title_author_ids = books.search_by_title_and_author(query).pluck(:id)
    memo_book_ids = current_user.memos.search_by_content(query).pluck(:book_id)

    Book.where(id: (title_author_ids + memo_book_ids).uniq)
  end

  def search_public_books(query)
    public_memo_scope = Memo.where(visibility: Memo::VISIBILITY[:public_site])
    book_ids = public_memo_scope.pluck(:book_id).uniq
    books = Book.where(id: book_ids)

    return books unless query.present?

    title_author_ids = books.search_by_title_and_author(query).pluck(:id)
    memo_book_ids = public_memo_scope.search_by_content(query).pluck(:book_id)

    Book.where(id: (title_author_ids + memo_book_ids).uniq)
  end
end
