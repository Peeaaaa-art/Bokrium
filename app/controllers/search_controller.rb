class SearchController < ApplicationController
  SEARCH_TYPES = %w[isbn author title].freeze
  APIs = [ OpenBdService, RakutenService, GoogleBooksService, NdlService ]

  def index
    type = params[:type]
    query = params[:query]
    engine = params[:engine] || "rakuten"
    page = (params[:page] || 1).to_i

    @query = query
    @page = page

    unless SEARCH_TYPES.include?(type) && query.present?
      @rakuten_book_results = []
      @rakuten_total_count = 0
      @rakuten_total_pages = 0
      return
    end

    if type == "isbn" || engine == "isbn"
      validator = Search::ValidateIsbnService.new(query)
      unless validator.valid?
        flash.now[:warning] = "#{query} #{validator.error_message}）"
        return
      end

      isbn13 = validator.isbn13
      @book_data = fetch_book_info(isbn13)

      unless @book_data.present?
        flash.now[:warning] = "該当する書籍が見つかりませんでした（ISBN: #{isbn13}）"
      end
      return
    end

    if engine == "rakuten"
      search_rakuten_books(type, query, page)
    else
      redirect_to search_google_books_path(query: query, page: page)
    end
  end



  def search_google_books
    query = params[:query]
    page = (params[:page] || 1).to_i
    return redirect_to search_books_path, alert: "検索キーワードがありません" if query.blank?
    @query = query
    @page = page

    response = GoogleBooksService.fetch_by_title_or_author(query, page)
    @google_book_results = response[:items] || []
    
    if @google_book_results.blank?
      if page == 1
        flash.now[:warning] = "Google Booksで該当する書籍が見つかりませんでした（#{query}）"
        @google_total_count = 0
        @google_total_pages = 0
      else
        flash.now[:warning] = "Google Booksでこれ以上の結果が見つかりませんでした（#{query}）"
        @google_total_count = (page - 1) * 30
        @google_total_pages = page - 1
      end
    end
    
    @google_total_count = [response[:total_count], 300].min
    @google_total_pages = (@google_total_count / 30.0).ceil

    render :index
  end

  def search_isbn_turbo
    isbn = params[:isbn]
    return head :bad_request if isbn.blank?

    begin
      book_info = fetch_book_info(isbn)

      if book_info.present?
        @book_data = book_info
        respond_to do |format|
          format.turbo_stream {
            render turbo_stream: turbo_stream.prepend(
              "scanned-books",
              partial: "search/isbn_result",
              locals: { book_data: @book_data }
            )
          }
        end
      else
        render turbo_stream: turbo_stream.prepend(
          "scanned-books",
          html: "<div class='alert alert-warning mt-2'>該当なし: #{isbn}</div>"
        )
      end
    rescue => e
      Rails.logger.error(e)
      render turbo_stream: turbo_stream.prepend(
        "scanned-books",
        html: "<div class='alert alert-danger'>システムエラーが発生しました</div>"
      )
    end
  end

  def barcode; end

  private


  def search_rakuten_books(type, query, page)
    begin
      results = RakutenWebService::Books::Book.search(type.to_sym => query, page: page, hits: 30)
      books = results.to_a
      @rakuten_book_results = books

      raw_count = results.response["count"].to_i
      @rakuten_total_count = [ raw_count, 300 ].min
      @rakuten_total_pages = (@rakuten_total_count / 30.0).ceil

      if books.blank?
        flash.now[:warning] = "楽天ブックスで該当する書籍が見つかりませんでした（#{query}）"
      end
    rescue RakutenWebService::Error => e
      flash[:error] = "楽天APIでエラーが発生しました: #{e.message}"
    end
  end

  def fetch_book_info(isbn)
    result = {}

    APIs.each do |api|
      api.fetch(isbn)&.compact&.each do |key, value|
        result[key] = value if result[key].blank?
      end

      break if complete?(result)
    end

    result
  end

  def complete?(data)
    data[:title].present? &&
    data[:author].present? &&
    data[:publisher].present? &&
    data[:book_cover].present?
  end
end
