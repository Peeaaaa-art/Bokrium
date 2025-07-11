# frozen_string_literal: true

class BookAutocompleteService
  def initialize(term:, scope:, user:)
    @term = term.to_s.strip
    @scope = scope
    @user = user
  end

  def call
    return [] if @term.blank?

    books = case @scope
    when "mine"
      @user.books.where("title ILIKE :t OR author ILIKE :t", t: "%#{@term}%").distinct.limit(10)
    when "public"
      public_book_ids = Memo.where(visibility: Memo::VISIBILITY[:public_site]).distinct.pluck(:book_id)
      Book.where(id: public_book_ids).where("title ILIKE :t OR author ILIKE :t", t: "%#{@term}%").limit(10)
    else
      []
    end

    books.map do |book|
      {
        value: book.title,
        label: "#{book.title}（#{book.author.presence || ''}）"
      }
    end
  end
end
