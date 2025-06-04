require 'rails_helper'

RSpec.describe IsbnCheck::IsbnService do
  describe '.normalize_validate_and_convert' do
    context '正しいISBN-10を与えた場合' do
      it 'ISBN-13に変換して返す' do
        isbn10 = '0-306-40615-2'
        expect(described_class.normalize_validate_and_convert(isbn10)).to eq('9780306406157')
      end
    end

    context '正しいISBN-13を与えた場合' do
      it 'そのまま正規化して返す' do
        isbn13 = '978-4-06-293842-6'
        expect(described_class.normalize_validate_and_convert(isbn13)).to eq('9784062938426')
      end
    end

    context '不正なISBNを与えた場合' do
      it '長さが足りない場合はエラーを投げる' do
        expect {
          described_class.normalize_validate_and_convert('123')
        }.to raise_error(IsbnCheck::IsbnService::InvalidIsbnError)
      end

      it 'チェックデジットが間違っている場合はエラーを投げる' do
        expect {
          described_class.normalize_validate_and_convert('9784062938427') # 最後の桁が誤り
        }.to raise_error(IsbnCheck::IsbnService::InvalidIsbnError)
      end
    end
  end

  describe '.normalize_isbn' do
    it 'ハイフンや空白を取り除き、大文字に変換する' do
      expect(described_class.normalize_isbn(' 978-4-06-293842-x ')).to eq('978406293842X')
    end
  end

  describe '.valid_isbn10?' do
    it '正しいISBN-10ならtrueを返す' do
      expect(described_class.valid_isbn10?('0-306-40615-2')).to be true
    end

    it '誤ったISBN-10ならfalseを返す' do
      expect(described_class.valid_isbn10?('0-306-40615-3')).to be false
    end
  end

  describe '.valid?' do
    it '正しいISBN-13ならtrueを返す' do
      expect(described_class.valid?('9784062938426')).to be true
    end

    it '正しいISBN-10ならtrueを返す' do
      expect(described_class.valid?('0-306-40615-2')).to be true
    end

    it '不正なISBNならfalseを返す' do
      expect(described_class.valid?('1234567890')).to be false
    end
  end

  describe '.isbn10_to_isbn13' do
    it 'ISBN-10を正しくISBN-13に変換する' do
      expect(described_class.isbn10_to_isbn13('0-306-40615-2')).to eq('9780306406157')
    end
  end

  describe '.calculate_isbn13_check_digit' do
    it '正しいチェックデジットを計算して返す' do
      expect(described_class.calculate_isbn13_check_digit('978030640615')).to eq('7')
    end
  end
end
