# frozen_string_literal: true

class BooksQuery
  # Docker の Postgres などで ja-x-icu が無い環境でもテストが通るようフォールバック
  class << self
    def ja_x_icu_available?
      return @ja_x_icu_available unless @ja_x_icu_available.nil?

      @ja_x_icu_available = ActiveRecord::Base.connection.select_value(
        "SELECT 1 FROM pg_collation WHERE collname = 'ja-x-icu' LIMIT 1"
      ).present?
    end
  end

  def initialize(books, params:, current_user:)
    @books = books
    @params = params
    @current_user = current_user
  end

  def call
    books = filter_by_tags(@books)
    books = filter_by_status(books)
    books = filter_by_memo_visibility(books)
    apply_sorting(books)
  end

  private

  def filter_by_tags(books)
    return books unless @params[:tags].present?

    tag_names = Array(@params[:tags])
    user_tag_ids = UserTag.where(user: @current_user, name: tag_names).pluck(:id)

    books.joins(:book_tag_assignments)
        .where(book_tag_assignments: { user_tag_id: user_tag_ids })
        .group("books.id")
  end

  def filter_by_status(books)
    return books unless @params[:status].present? && Book.statuses.key?(@params[:status])

    books.where(status: @params[:status])
  end


  def filter_by_memo_visibility(books)
    return books unless @params[:memo_visibility].present?

    visibility = Memo::VISIBILITY[@params[:memo_visibility].to_sym]
    return books unless visibility

    books
      .joins(:memos)
      .where(memos: { visibility: visibility })
      .group("books.id")
  end

  def apply_sorting(books)
    case @params[:sort]
    when "oldest"
      books.order(created_at: :asc)
    when "title_asc"
      books.order(Arel.sql(ja_collate_sql("title", "ASC")))
    when "author_asc"
      books.order(Arel.sql(ja_collate_sql("author", "ASC")))
    when "latest_memo"
      books
        .left_joins(:memos)
        .group("books.id")
        .order(Arel.sql("MAX(memos.updated_at) DESC NULLS LAST"))
    else
      books.order(created_at: :desc)
    end
  end

  def ja_collate_sql(column, direction)
    if self.class.ja_x_icu_available?
      "#{column} COLLATE \"ja-x-icu\" #{direction}"
    else
      "#{column} #{direction}"
    end
  end
end
