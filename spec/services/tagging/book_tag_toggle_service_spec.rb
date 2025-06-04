require 'rails_helper'

RSpec.describe Tagging::BookTagToggleService, type: :service do
  let(:user) { create(:user) }
  let(:book) { create(:book, user: user) }
  let(:tag_name) { "テストタグ" }
  let(:flash) { {} }

  describe '#call' do
    context 'タグが存在し、まだ付与されていない場合' do
      let!(:tag) { ActsAsTaggableOn::Tag.create!(name: tag_name, user: user) }

      it 'タグを付与し、flashにinfoメッセージをセットする' do
        service = described_class.new(book: book, user: user, tag_name: tag_name, flash: flash)

        expect {
          result = service.call
          expect(result).to be true
          book.reload
        }.to change {
          book.taggings.includes(:tag).map(&:tag).map(&:name)
        }.from([]).to([ tag_name ])

        expect(flash[:info]).to eq "『#{tag_name}』をタグ付けしました"
      end
    end

    context 'タグが存在し、すでに付与されている場合' do
      let!(:tag) { ActsAsTaggableOn::Tag.create!(name: tag_name, user: user) }

      before do
        book.tag_list.add(tag_name)
        book.save!
        book.taggings.update_all(tagger_id: user.id, tagger_type: "User")
        book.reload
      end

      it 'タグを解除し、flashにinfoメッセージをセットする' do
        service = described_class.new(book: book, user: user, tag_name: tag_name, flash: flash)

        result = service.call

        expect(result).to be true
        book.reload

        expect(book.tag_list_on(:tags)).to eq []
        expect(flash[:info]).to eq "『#{tag_name}』のタグを解除しました"
      end
    end

    context 'タグが存在しない場合' do
      it 'falseを返し、flashにエラーメッセージを設定する' do
        service = described_class.new(book: book, user: user, tag_name: '存在しないタグ', flash: flash)

        result = service.call

        expect(result).to be false
        expect(flash[:danger]).to eq 'タグが見つかりません'
      end
    end

    context '保存時に例外が発生する場合' do
      let!(:tag) { ActsAsTaggableOn::Tag.create!(name: tag_name, user: user) }

      before do
        allow(book).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(book))
      end

      it 'falseを返し、flashにエラーメッセージを設定する' do
        service = described_class.new(book: book, user: user, tag_name: tag_name, flash: flash)

        result = service.call

        expect(result).to be false
        expect(flash[:danger]).to include('タグ操作中にエラーが発生しました')
      end
    end
  end
end
