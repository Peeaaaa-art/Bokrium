module IsbnCheck
  class IsbnService
    class InvalidIsbnError < StandardError; end

    ISBN_10_LENGTH = 10
    ISBN_13_LENGTH = 13
    ISBN_13_PREFIX = "978"
    ISBN_13_MULTIPLIERS = [ 1, 3 ]

    def self.normalize_validate_and_convert(isbn)
      normalized = normalize_isbn(isbn)

      case normalized.length
      when ISBN_10_LENGTH
        raise InvalidIsbnError unless valid_isbn10?(normalized)
        isbn10_to_isbn13(normalized)

      when ISBN_13_LENGTH
        raise InvalidIsbnError unless valid?(normalized)
        normalized

      else
        raise InvalidIsbnError
      end
    end

    def self.normalize_isbn(isbn)
      isbn.to_s.gsub(/[\s-]/, "").gsub(/[^0-9X]/i, "").upcase
    end

    def self.valid?(isbn)
      normalized = normalize_isbn(isbn)
      case normalized.length
      when ISBN_10_LENGTH
        valid_isbn10?(normalized)
      when ISBN_13_LENGTH
        calculate_isbn13_check_digit(normalized[0..11]) == normalized[12]
      else
        false
      end
    end

    def self.valid_isbn10?(isbn10)
      normalized = normalize_isbn(isbn10)
      return false unless normalized.length == 10
      return false unless normalized[0..8].match?(/^\d{9}$/) && normalized[9].match?(/[\dX]/i)

      sum = normalized.each_char.with_index.sum do |char, i|
        digit = (char.downcase == "x") ? 10 : char.to_i
        digit * (10 - i)
      end

      sum % 11 == 0
    end

    def self.isbn10_to_isbn13(isbn10)
      normalized = normalize_isbn(isbn10)
      isbn12 = ISBN_13_PREFIX + normalized[0..8]
      check_digit = calculate_isbn13_check_digit(isbn12)
      isbn12 + check_digit
    end

    def self.calculate_isbn13_check_digit(isbn12)
      sum = isbn12.each_char.with_index.sum do |digit, index|
        digit.to_i * ISBN_13_MULTIPLIERS[index % 2]
      end
      ((10 - (sum % 10)) % 10).to_s
    end
  end
end
