class ExploreController < ApplicationController
  def index
    @has_books = Book.exists?(user_id: current_user&.id)
    @query = params[:q].to_s.strip
    @scope = params[:scope].presence_in(%w[mine public]) || "public"

    display = BooksDisplaySetting.new(session, params, {
      shelf:       default_books_per_shelf,
      card:        default_card_columns,
      detail_card: default_detail_card_columns,
      spine:       default_spine_per_shelf
    }, mobile: mobile?)

    @view_mode           = display.view_mode
    @books_per_shelf     = display.books_per_shelf
    @card_columns        = display.card_columns
    @detail_card_columns = display.detail_card_columns
    @spine_per_shelf     = display.spine_per_shelf

    if @scope == "mine"
      return redirect_to new_user_session_path unless user_signed_in?

      books = current_user.books.includes(:memos, book_cover_s3_attachment: :blob)
      books = BooksQuery.new(books, params: params, current_user: current_user).call

      if @query.present?
        title_author_ids = books.search_by_title_and_author(@query).pluck(:id)
        memo_book_ids = current_user.memos.search_by_content(@query).pluck(:book_id)
        books = books.where(id: (title_author_ids + memo_book_ids).uniq)
      end

      books_per_page = (display.unit_per_page * 3).to_i
      @pagy, @books = pagy(books, items: books_per_page)
    else
      @results = search_public_memos(@query)
      @pagy, @memos = pagy(@results, items: 20)
    end

    if turbo_frame_request?
      turbo_render_partial!
    else
      render :index
    end
  end

  private

  def turbo_render_partial!
    if @scope == "mine"
      render turbo_stream: turbo_stream.update(
        "books_frame",
        partial: "bookshelf/books_frame_wrapper",
        locals: {
          view_mode: @view_mode,
          books: @books,
          pagy: @pagy,
          books_per_shelf: @books_per_shelf,
          card_columns: @card_columns,
          detail_card_columns: @detail_card_columns,
          spine_per_shelf: @spine_per_shelf
        }
      )
    else
      render turbo_stream: turbo_stream.update(
        "books_frame",
        partial: "public_bookshelf/public_card",
        locals: { memos: @memos, pagy: @pagy }
      )
    end
  end

  def search_public_memos(query)
    scope = Memo.where(visibility: Memo::VISIBILITY[:public_site]).includes(:book, :user)
    return scope unless query.present?

    book_ids = Book.search_by_title_and_author(query).pluck(:id)
    memo_ids = scope.search_by_content(query).pluck(:id)
    scope.where(id: memo_ids).or(scope.where(book_id: book_ids))
  end
end
