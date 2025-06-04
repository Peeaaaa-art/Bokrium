require 'rails_helper'

RSpec.describe IsbnCheck::ValidateIsbnService do
  describe '#valid?' do
    context 'ISBNが空の場合' do
      it 'falseを返し、エラーメッセージがblankである' do
        service = described_class.new("")
        expect(service.valid?).to be false
        expect(service.error_message).to eq(I18n.t("errors.messages.blank"))
      end
    end

    context '不正なISBNの場合' do
      it 'falseを返し、エラーメッセージがinvalid_isbnである' do
        service = described_class.new("invalid-isbn")
        expect(service.valid?).to be false
        expect(service.error_message).to eq(I18n.t("errors.messages.invalid_isbn"))
      end
    end

    context '正しいISBN-10を渡した場合' do
      it 'trueを返し、ISBN-13に変換される' do
        service = described_class.new("0-306-40615-2")
        expect(service.valid?).to be true
        expect(service.isbn13).to eq("9780306406157")
        expect(service.error_message).to be_nil
      end
    end

    context '正しいISBN-13を渡した場合' do
      it 'trueを返し、isbn13がそのまま返る' do
        service = described_class.new("978-4-06-293842-6")
        expect(service.valid?).to be true
        expect(service.isbn13).to eq("9784062938426")
        expect(service.error_message).to be_nil
      end
    end
  end
end
