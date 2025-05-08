module IsbnCheck
  class ValidateIsbnService
    attr_reader :isbn, :isbn13, :error_message

    def initialize(isbn)
      @isbn = isbn.to_s
      @error_message = nil
    end

    def valid?
      if isbn.blank?
        @error_message = I18n.t("errors.messages.blank")
        return false
      end

      begin
        @isbn13 = IsbnService.normalize_validate_and_convert(isbn)
        true
      rescue IsbnService::InvalidIsbnError
        @error_message = I18n.t("errors.messages.invalid_isbn")
        false
      end
    end
  end
end
