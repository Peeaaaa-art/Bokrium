class ExploreController < ApplicationController
  def index
    @has_books = Book.exists?(user_id: current_user&.id)
    @query = params[:q].to_s.strip
    @scope = params[:scope].presence_in(%w[mine guest]) || (user_signed_in? ? "mine" : "guest")

    case @scope
    when "mine"
      return redirect_to new_user_session_path unless user_signed_in?

      presenter = BooksIndexPresenter.new(
        user: current_user,
        params: params,
        session: session,
        mobile: mobile?,
        user_agent: request.user_agent
      ).call

      @view_mode           = presenter.view_mode
      @books_per_shelf     = presenter.books_per_shelf
      @card_columns        = presenter.card_columns
      @detail_card_columns = presenter.detail_card_columns
      @spine_per_shelf     = presenter.spine_per_shelf
      @read_only           = presenter.read_only

      books = user_books_for(current_user)
      books = BooksQuery.new(books, params: params, current_user: current_user).call
      books = filter_by_query(books, current_user)

      books_per_page = (presenter.display.unit_per_page * 3).to_i
      @pagy, @books = pagy(books, items: books_per_page)
      @next_page_path = next_page_path

    when "guest"
      presenter = BooksIndexPresenter.new(
        user: guest_user,
        params: params,
        session: session,
        mobile: mobile?,
        user_agent: request.user_agent
      ).call

      @view_mode           = presenter.view_mode
      @books_per_shelf     = presenter.books_per_shelf
      @card_columns        = presenter.card_columns
      @detail_card_columns = presenter.detail_card_columns
      @spine_per_shelf     = presenter.spine_per_shelf
      @read_only           = true

      books = user_books_for(guest_user)
      books = BooksQuery.new(books, params: params, current_user: guest_user).call
      books = filter_by_query(books, guest_user)

      books_per_page = (presenter.display.unit_per_page * 3).to_i
      @pagy, @books = pagy(books, items: books_per_page)
      @next_page_path = next_page_path

    end

    if turbo_frame_request?
      turbo_render_partial!
    else
      render :index
    end
  end

  private

  def turbo_render_partial!
    return unless %w[mine guest].include?(@scope)

    case request.headers["Turbo-Frame"]
    when "next_books"
      render_chunk_for(@view_mode)
    else
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
          spine_per_shelf: @spine_per_shelf,
          next_page_path: @next_page_path
        }
      )
    end
  end

  def render_chunk_for(view_mode)
    case view_mode
    when "shelf"
      render partial: "bookshelf/kino_chunk",
            locals: { books: @books, books_per_shelf: @books_per_shelf, pagy: @pagy, next_page_path: @next_page_path }
    when "spine"
      render partial: "bookshelf/spine_chunk",
            locals: { books: @books, spine_per_shelf: @spine_per_shelf, pagy: @pagy, next_page_path: @next_page_path }
    when "card"
      render partial: "bookshelf/card_chunk",
            locals: { books: @books, pagy: @pagy, card_columns: @card_columns, next_page_path: @next_page_path }
    when "detail_card"
      render partial: "bookshelf/detail_card_chunk",
            locals: { books: @books, pagy: @pagy, detail_card_columns: @detail_card_columns, next_page_path: @next_page_path }
    when "b_note"
      render partial: "bookshelf/b_chunk",
            locals: { books: @books, pagy: @pagy, next_page_path: @next_page_path }
    end
  end

  def next_page_path
    return unless @pagy&.next

    explore_path(request.query_parameters.merge(page: @pagy.next, view: @view_mode))
  end

  def user_books_for(user)
    if @view_mode == "b_note"
      user.books.select(:id, :title, :author, :publisher)
    else
      user.books.includes(book_cover_s3_attachment: :blob)
    end
  end

  def filter_by_query(books, user)
    return books if @query.blank?

    title_author_ids = books.fuzzy_title_or_author(@query).pluck(:id)
    memo_book_ids = user.memos.search_by_content(@query).pluck(:book_id)
    books.where(id: (title_author_ids + memo_book_ids).uniq)
  end
end
