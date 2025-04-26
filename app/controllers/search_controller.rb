class SearchController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:search_isbn_turbo]
  SEARCH_TYPES = %w[isbn author title].freeze

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
      redirect_to root_path
    end
  end

  def search_isbn_turbo
    isbn = params[:isbn]
    return head :bad_request if isbn.blank?
  
    begin
      results = RakutenWebService::Books::Book.search(isbn: isbn)
      if results.present?
        @book_data = results.first
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
    rescue RakutenWebService::Error => e
      Rails.logger.error(e)
      render turbo_stream: turbo_stream.append(
        "scanned-books",
        html: "<div class='alert alert-danger'>エラー: #{e.message}</div>"
      )
    rescue => e
      Rails.logger.error(e)
      render turbo_stream: turbo_stream.append(
        "scanned-books",
        html: "<div class='alert alert-danger'>システムエラーが発生しました</div>"
      )
    end
  end
  
  def barcode; end
end
