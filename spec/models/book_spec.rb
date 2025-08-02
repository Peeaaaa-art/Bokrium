require 'rails_helper'

RSpec.describe Book, type: :model do
  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:book)).to be_valid
    end
  end

  describe "バリデーション" do
    it "タイトルのみ入力されていれば保存できる（他は空）" do
      book = build(:book, title: "タイトルだけの本", author: nil, publisher: nil, page: nil, price: nil, isbn: nil)
      expect(book).to be_valid
    end

    it "タイトルが空だと無効" do
      book = build(:book, title: nil)
      expect(book).not_to be_valid
      expect(book.errors[:title]).to include(": タイトルは必須です")
    end

    it "タイトルが100文字を超えると無効" do
      book = build(:book, title: "あ" * 101)
      expect(book).not_to be_valid
      expect(book.errors[:title]).to include(": タイトルは100文字以内で入力してください")
    end

    it "著者が100文字を超えると無効" do
      book = build(:book, author: "著" * 101)
      expect(book).not_to be_valid
      expect(book.errors[:author]).to include(": 著者は100文字以内で入力してください")
    end

    it "出版社が50文字を超えると無効" do
      book = build(:book, publisher: "社" * 51)
      expect(book).not_to be_valid
      expect(book.errors[:publisher]).to include(": 出版社は50文字以内で入力してください")
    end

    it "ページ数が負だと無効" do
      book = build(:book, page: -1)
      expect(book).not_to be_valid
      expect(book.errors[:page]).to include(": ページ数は50560ページ以下で入力してください")
    end

    it "ページ数が50561だと無効" do
      book = build(:book, page: 50_561)
      expect(book).not_to be_valid
      expect(book.errors[:page]).to include(": ページ数は50560ページ以下で入力してください")
    end

    it "金額がマイナスだと無効" do
      book = build(:book, price: -1)
      expect(book).not_to be_valid
      expect(book.errors[:price]).to include(": 金額は100万円以下で指定してください")
    end

    it "金額が100万円超だと無効" do
      book = build(:book, price: 1_000_001)
      expect(book).not_to be_valid
      expect(book.errors[:price]).to include(": 金額は100万円以下で指定してください")
    end

    it "ISBNが14文字だと無効" do
      book = build(:book, isbn: "12345678901234")
      expect(book).not_to be_valid
      expect(book.errors[:isbn]).to include(": ISBNは数字とXのみで13文字以内で入力してください")
    end

    it "ISBNが不正文字を含むと無効" do
      book = build(:book, isbn: "978abc@@@")
      expect(book).not_to be_valid
      expect(book.errors[:isbn]).to include(": ISBNは数字とXのみで13文字以内で入力してください")
    end

    it "ISBNがXを含んで13文字以内なら有効" do
      book = build(:book, isbn: "123456789X")
      expect(book).to be_valid
    end

    it "ISBNが同一ユーザーで重複すると無効" do
      user = create(:user)
      create(:book, user: user, isbn: "9781234567890")
      duplicate = build(:book, user: user, isbn: "9781234567890")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:isbn]).to include(": この書籍は本棚に登録済みです")
    end

    it "別ユーザーなら同じISBNで保存可能" do
      create(:book, user: create(:user), isbn: "9781234567890")
      other = build(:book, user: create(:user), isbn: "9781234567890")
      expect(other).to be_valid
    end

    it "ISBNが空文字列ならnilに正規化される" do
      book = build(:book, isbn: "")
      book.validate
      expect(book.isbn).to be_nil
      expect(book).to be_valid
    end
  end

  describe "アソシエーション" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:memos).dependent(:destroy) }
    it { is_expected.to have_many(:images).dependent(:destroy) }
    it { is_expected.to have_many(:book_tag_assignments).dependent(:destroy) }
    it { is_expected.to have_many(:user_tags).through(:book_tag_assignments) }

    it "book_cover_s3 が ActiveStorage アタッチメントとして使用できる" do
      expect(Book.new).to respond_to(:book_cover_s3)
    end
  end

  describe "タグ機能" do
    it "タグを付与できる" do
      user = create(:user)
      book = create(:book, user: user)
      tag1 = create(:user_tag, user: user, name: "思想")
      tag2 = create(:user_tag, user: user, name: "文学")
      book.book_tag_assignments.create!(user_tag: tag1, user: user)
      book.book_tag_assignments.create!(user_tag: tag2, user: user)
      expect(book.user_tags.map(&:name)).to include("思想", "文学")
    end
  end

  describe "ステータス(enum)" do
    it "初期状態は want_to_read" do
      book = build(:book)
      expect(book.status).to eq("want_to_read")
    end

    it "statusを変更できる" do
      book = build(:book, status: :reading)
      expect(book.status).to eq("reading")
      book.status = :finished
      expect(book.status).to eq("finished")
    end
  end

  describe "pg_search_scope :search_by_title_and_author" do
    let(:user) { create(:user) }
    let!(:book1) { create(:book, title: "星の王子さま", author: "サン＝テグジュペリ", user: user) }
    let!(:book2) { create(:book, title: "アルケミスト", author: "パウロ・コエーリョ", user: user) }

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
