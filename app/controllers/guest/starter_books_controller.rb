module Guest
  class StarterBooksController < ApplicationController
    # CHUNKS_PER_PAGE = 14

    before_action :set_know_how_book, only: [ :index ]
    rescue_from ActiveRecord::RecordNotFound, with: :handle_guest_not_found

    def index
      display = BooksDisplaySetting.new(session, params, {
        shelf: default_books_per_shelf,
        card: default_card_columns
      })

      @books_per_shelf = display.books_per_shelf
    end

    private

    def set_know_how_book
      isbn_list = %w[9781001001001]
      @books = guest_user.books.where(isbn: isbn_list)
    end

    def handle_guest_not_found
      flash[:danger] = "この本はゲスト表示できません"
      redirect_to root_path
    end
  end
end
