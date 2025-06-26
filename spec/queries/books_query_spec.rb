require 'rails_helper'

RSpec.describe BooksQuery do
  let(:user) { create(:user) }
  let(:params) { {} }

  describe '#call' do
    context 'タグでフィルターできる' do
      let!(:book1) { create(:book, user: user, title: "アルケミスト") }
      let!(:book2) { create(:book, user: user, title: "存在と時間") }

      before do
        tag_philosophy = create(:user_tag, name: "哲学", user: user)
        tag_religion = create(:user_tag, name: "宗教", user: user)

        create(:book_tag_assignment, book: book1, user_tag: tag_philosophy, user: user)
        create(:book_tag_assignment, book: book2, user_tag: tag_religion, user: user)
      end

      it '「哲学」タグが付いた本だけを取得できること' do
        result = described_class.new(Book.all, params: { tags: [ "哲学" ] }, current_user: user).call
        expect(result).to contain_exactly(book1)
      end
    end

    context 'ステータスでフィルターできる' do
      let!(:book1) { create(:book, user: user, status: :want_to_read) }
      let!(:book2) { create(:book, user: user, status: :finished) }

      it 'ステータスが「読みたい」の本だけを取得できること' do
        result = described_class.new(Book.all, params: { status: "want_to_read" }, current_user: user).call
        expect(result).to contain_exactly(book1)
      end
    end

    context '古い順にソートできる' do
      let!(:book1) { create(:book, user: user, created_at: 1.day.ago) }
      let!(:book2) { create(:book, user: user, created_at: Time.current) }

      it '作成日の古い順に並ぶこと' do
        result = described_class.new(Book.all, params: { sort: "oldest" }, current_user: user).call
        expect(result).to eq [ book1, book2 ]
      end
    end

    context 'タイトル順にソートできる（ja-x-icu）' do
      let!(:book1) { create(:book, user: user, title: "いぬ") }
      let!(:book2) { create(:book, user: user, title: "あか") }

      it 'タイトルの昇順（五十音順）で並ぶこと' do
        result = described_class.new(Book.all, params: { sort: "title_asc" }, current_user: user).call
        expect(result).to eq [ book2, book1 ]
      end
    end

    context '著者順にソートできる' do
      let!(:book1) { create(:book, user: user, author: "田中") }
      let!(:book2) { create(:book, user: user, author: "阿部") }

      it '著者名の昇順で並ぶこと' do
        result = described_class.new(Book.all, params: { sort: "author_asc" }, current_user: user).call
        expect(result).to eq [ book2, book1 ]
      end
    end

    context 'メモの更新順にソートできる' do
      let!(:book1) { create(:book, user: user) }
      let!(:book2) { create(:book, user: user) }

      before do
        create(:memo, book: book1, updated_at: 1.day.ago)
        create(:memo, book: book2, updated_at: Time.current)
      end

      it '最新のメモがある本から順に並ぶこと' do
        result = described_class.new(Book.all, params: { sort: "latest_memo" }, current_user: user).call
        expect(result).to eq [ book2, book1 ]
      end
    end

    context 'デフォルトで新しい順にソートされる' do
      let!(:book1) { create(:book, user: user, created_at: 1.day.ago) }
      let!(:book2) { create(:book, user: user, created_at: Time.current) }

      it 'パラメータが指定されていない場合、新しい順に並ぶこと' do
        result = described_class.new(Book.all, params: {}, current_user: user).call
        expect(result).to eq [ book2, book1 ]
      end
    end
  end
end
