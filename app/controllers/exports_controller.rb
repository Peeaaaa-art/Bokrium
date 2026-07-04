require "csv"

class ExportsController < ApplicationController
  before_action :authenticate_user!

  def books
    csv_data = CSV.generate(headers: true) do |csv|
      csv << %w[title author isbn publisher page price status tags memos]

      current_user.books.includes(:user_tags, :memos).order(:created_at).each do |book|
        tags = book.user_tags.map(&:name).join(",")
        memos = book.memos.sort_by(&:created_at).map(&:content).join("\n---\n")

        csv << [
          book.title,
          book.author,
          book.isbn,
          book.publisher,
          book.page,
          book.price,
          book.status,
          tags,
          memos
        ]
      end
    end

    send_data csv_data, filename: "bokrium_books_#{Date.current}.csv", type: "text/csv"
  end
end
