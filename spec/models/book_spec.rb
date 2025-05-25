require 'rails_helper'

RSpec.describe Book, type: :model do
  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:book)).to be_valid
    end
  end

  describe "バリデーション" do
    it "ISBNが重複する場合は無効（同じユーザー内）" do
      user = create(:user)
      create(:book, user: user, isbn: "9781234567890")
      duplicate = build(:book, user: user, isbn: "9781234567890")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:isbn]).to include(": この書籍はMy本棚に登録済みです")
    end

    it "ISBNが空文字列なら保存される（normalize_isbn）" do
      book = build(:book, isbn: "")
      book.validate
      expect(book.isbn).to be_nil
      expect(book).to be_valid
    end

    it "別のユーザーなら同じISBNを登録できる" do
      isbn = "9781234567890"
      create(:book, user: create(:user), isbn: isbn)
      another = build(:book, user: create(:user), isbn: isbn)
      expect(another).to be_valid
    end
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:memos).dependent(:destroy) }
    it { is_expected.to have_many(:images).dependent(:destroy) }

    it "book_cover_s3 がアタッチ可能であること" do
      expect(Book.new).to respond_to(:book_cover_s3)
    end
  end

  describe "タグ機能" do
    it "タグを付けられる" do
      user = create(:user)
      book = create(:book, user: user)

      ActsAsTaggableOn::Tag.class_eval do
        before_validation do
          self.user_id ||= user.id
        end
      end

      book.tag_list.add("哲学", "小説")
      book.save!
      expect(book.reload.tag_list).to include("哲学", "小説")
    end
  end

  describe "ステータス (enum)" do
    it "初期状態は want_to_read" do
      book = build(:book)
      expect(book.status).to eq("want_to_read")
    end

    it "reading や finished に変更できる" do
      book = build(:book, status: :reading)
      expect(book.status).to eq("reading")

      book.status = :finished
      expect(book.status).to eq("finished")
    end
  end

  describe "pg_search_scope :search_by_title_and_author" do
    let(:user) { create(:user) }
    let!(:book1) { create(:book, title: "星の王子さま", author: "サン＝テグジュペリ", isbn: "9781111111111", user: user) }
    let!(:book2) { create(:book, title: "アルケミスト", author: "パウロ・コエーリョ", isbn: "9782222222222", user: user) }
    it "タイトルで検索できる" do
      results = Book.search_by_title_and_author("星の王子")
      expect(results).to include(book1)
      expect(results).not_to include(book2)
    end

    it "著者名で検索できる" do
      results = Book.search_by_title_and_author("パウロ")
      expect(results).to include(book2)
      expect(results).not_to include(book1)
    end
  end
end
