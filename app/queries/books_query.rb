# frozen_string_literal: true

class BooksQuery
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
        .distinct
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
      books.order(Arel.sql("title COLLATE \"ja-x-icu\" ASC"))
    when "author_asc"
      books.order(Arel.sql("author COLLATE \"ja-x-icu\" ASC"))
    when "latest_memo"
      books.left_joins(:memos).group("books.id").order(Arel.sql("MAX(memos.updated_at) DESC NULLS LAST"))
    else
      books.order(created_at: :desc)
    end
  end
end
