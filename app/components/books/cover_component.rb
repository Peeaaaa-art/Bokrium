# frozen_string_literal: true

module Books
  class CoverComponent < ViewComponent::Base
    include ActionView::Helpers::SanitizeHelper

    def initialize(book:, alt: nil, s3_class: "", url_class: "",
                   no_cover_class: "", truncate_options: {}, **options)
      @book = book
      @alt = alt || book.title.presence || "表紙画像"
      @s3_class = s3_class
      @url_class = url_class
      @no_cover_class = no_cover_class
      @truncate_options = truncate_options
      @options = options
    end

    def show_s3_cover?
      @book.book_cover_s3.attached? && @book.book_cover_s3.key.present?
    end

    def show_url_cover?
      @book.book_cover.present?
    end

    def bokrium_cover_url
      @book.bokrium_cover_url
    end

    def title_for_overlay
      helpers.truncate_for_device(@book.title, **@truncate_options)
    end
  end
end
