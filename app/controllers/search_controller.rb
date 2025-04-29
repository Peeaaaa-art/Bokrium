class SearchController < ApplicationController
  SEARCH_TYPES = %w[isbn author title].freeze
  APIs = [  NdlService ]
  def index
    type = params[:type]
    query = params[:query]
    page = (params[:page] || 1).to_i

    unless SEARCH_TYPES.include?(type) && query.present?
      @book_results = []
      @total_count = 0
      @total_pages = 0
      return
    end

    begin
      results = RakutenWebService::Books::Book.search(type.to_sym => query, page: page, hits: 30)
      books = results.to_a

      if type == "isbn" && books.present?
        @book_data = books.first
      else
        @book_results = books
        raw_count = results.response["count"].to_i
        @total_count = [ raw_count, 300 ].min
        @total_pages = (@total_count / 30.0).ceil
      end
    rescue RakutenWebService::Error => e
      flash[:error] = "楽天APIでエラーが発生しました: #{e.message}"
    end
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
            render turbo_stream: turbo_stream.append(
              "scanned-books",
              partial: "search/isbn_result",
              locals: { book_data: @book_data }
            )
          }
        end
      else
        render turbo_stream: turbo_stream.append(
          "scanned-books",
          html: "<div class='alert alert-warning mt-2'>該当なし: #{isbn}</div>"
        )
      end
    rescue => e
      Rails.logger.error(e)
      render turbo_stream: turbo_stream.append(
        "scanned-books",
        html: "<div class='alert alert-danger'>システムエラーが発生しました</div>"
      )
    end
  end

  def barcode; end


  private

  def fetch_book_info(isbn)
    result = {}

    APIs.each do |api|
      data = api.fetch(isbn)
      if data
        result.merge!(data.compact)
        Rails.logger.info("[BookSearch] #{api.name} から情報取得（ISBN: #{isbn}）")
      end

      break if complete?(result)
    end

    Rails.logger.info("[BookSearch] 検索完了（ISBN: #{isbn}） -> 取得元: #{result_source(result)}")
    result
  end

  def complete?(data)
    data[:title].present? &&
    data[:author].present? &&
    data[:publisher].present? &&
    data[:isbn].present? &&
    data[:price].present? &&
    data[:page].present? &&
    data[:book_cover].present?
  end

  def result_source(result)
    keys = %i[title author publisher isbn price page book_cover]
    present_keys = keys.select { |k| result[k].present? }
    "取得項目: #{present_keys.join(', ')}"
  end
end
