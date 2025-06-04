require 'rails_helper'

RSpec.describe BooksQuery do
  let(:user) { create(:user) }
  let(:params) { {} }

  describe '#call' do
    context 'タグでフィルターできる' do
      let(:book1) { create(:book, user: user, title: "アルケミスト") }
      let(:book2) { create(:book, user: user, title: "存在と時間") }

      before do
        ActsAsTaggableOn::Tag.create!(name: "哲学", user: user)
        ActsAsTaggableOn::Tag.create!(name: "宗教", user: user)

        book1.tag_list.add("哲学")
        book1.save!
        book1.taggings.update_all(tagger_id: user.id, tagger_type: "User")

        book2.tag_list.add("宗教")
        book2.save!
        book2.taggings.update_all(tagger_id: user.id, tagger_type: "User")
      end

      it '哲学タグの本だけ取得する' do
        result = described_class.new(Book.all, params: { tags: [ "哲学" ] }, current_user: user).call
        expect(result).to contain_exactly(book1)
      end
    end

    context 'ステータスでフィルターできる' do
      let!(:book1) { create(:book, user: user, status: :want_to_read) }
      let!(:book2) { create(:book, user: user, status: :finished) }

      it '読みたい本だけ取得する' do
        result = described_class.new(Book.all, params: { status: "want_to_read" }, current_user: user).call
        expect(result).to contain_exactly(book1)
      end
    end

    context '古い順にソートできる' do
      let!(:book1) { create(:book, user: user, created_at: 1.day.ago) }
      let!(:book2) { create(:book, user: user, created_at: Time.current) }

      it do
        result = described_class.new(Book.all, params: { sort: "oldest" }, current_user: user).call
        expect(result).to eq [ book1, book2 ]
      end
    end

    context 'タイトル順にソートできる（ja-x-icu）' do
      let!(:book1) { create(:book, user: user, title: "いぬ") }
      let!(:book2) { create(:book, user: user, title: "あか") }

      it do
        result = described_class.new(Book.all, params: { sort: "title_asc" }, current_user: user).call
        expect(result).to eq [ book2, book1 ] # あか → いぬ
      end
    end

    context '著者順にソートできる' do
      let!(:book1) { create(:book, user: user, author: "田中") }
      let!(:book2) { create(:book, user: user, author: "阿部") }

      it do
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

      it do
        result = described_class.new(Book.all, params: { sort: "latest_memo" }, current_user: user).call
        expect(result).to eq [ book2, book1 ]
      end
    end

    context 'デフォルトで新しい順にソートされる' do
      let!(:book1) { create(:book, user: user, created_at: 1.day.ago) }
      let!(:book2) { create(:book, user: user, created_at: Time.current) }

      it do
        result = described_class.new(Book.all, params: {}, current_user: user).call
        expect(result).to eq [ book2, book1 ]
      end
    end
  end
end
