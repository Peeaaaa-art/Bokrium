# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BookTagToggleService, type: :service do
  let(:user) { create(:user) }
  let(:book) { create(:book, user: user) }
  let(:tag)  { create(:user_tag, name: "テストタグ", user: user) }
  let(:flash) { {} }

  describe '#call' do
    context 'タグが存在し、まだ付与されていない場合' do
      it 'タグを付与し、flashにinfoメッセージをセットする' do
        service = described_class.new(book: book, user: user, tag_id: tag.id, flash: flash)

        expect {
          result = service.call
          expect(result).to be true
        }.to change { BookTagAssignment.count }.by(1)

        assignment = BookTagAssignment.last
        expect(assignment.book).to eq book
        expect(assignment.user_tag).to eq tag
        expect(assignment.user_id).to eq user.id
        expect(flash[:info]).to eq "タグ「#{tag.name}」を追加しました"
      end
    end

    context 'すでに付与されている場合' do
      before do
        BookTagAssignment.create!(book: book, user_tag: tag, user: user)
      end

      it 'タグを解除し、flashにinfoメッセージをセットする' do
        service = described_class.new(book: book, user: user, tag_id: tag.id, flash: flash)

        expect {
          result = service.call
          expect(result).to be true
        }.to change { BookTagAssignment.count }.by(-1)

        expect(book.book_tag_assignments.where(user_tag_id: tag.id)).to be_empty
        expect(flash[:info]).to eq "タグ「#{tag.name}」を解除しました"
      end
    end

    context '存在しないタグIDを指定した場合' do
      it 'falseを返し、flashにエラーメッセージを設定する' do
        service = described_class.new(book: book, user: user, tag_id: 999999, flash: flash)

        result = service.call

        expect(result).to be false
        expect(flash[:danger]).to include('タグ操作中にエラーが発生しました')
      end
    end

    context '保存時に例外が発生する場合' do
      before do
        allow(book.book_tag_assignments).to receive(:create!).and_raise(ActiveRecord::RecordInvalid.new(BookTagAssignment.new))
      end

      it 'falseを返し、flashにエラーメッセージを設定する' do
        service = described_class.new(book: book, user: user, tag_id: tag.id, flash: flash)

        result = service.call

        expect(result).to be false
        expect(flash[:danger]).to include('タグ操作中にエラーが発生しました')
      end
    end
  end
end
