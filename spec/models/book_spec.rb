require 'rails_helper'

RSpec.describe Book, type: :model do
  describe "ファクトリ" do
    it "有効なファクトリを持つ" do
      expect(build(:book)).to be_valid
    end
  end

  describe "バリデーション" do
    it "タイトルのみ入力されていれば保存できる（他は空）" do
      book = build(:book,
        title: "タイトルだけの本",
        author: nil,
        publisher: nil,
        page: nil,
        price: nil,
        isbn: nil
      )

      expect(book).to be_valid
    end
    it "タイトルが空だと無効" do
      book = FactoryBot.build(:book, title: nil)
      expect(book).not_to be_valid
    end

    it "タイトルが100文字を超えると無効" do
      book = build(:book, title: "あ" * 101)
      expect(book).not_to be_valid
      expect(book.errors[:title]).to include(": タイトルは100文字以内で入力してください")
    end

    it "著者が50文字を超えると無効" do
      book = build(:book, author: "作" * 51)
      expect(book).not_to be_valid
      expect(book.errors[:author]).to include(": 著者は50文字以内で入力してください")
    end

    it "出版社が50文字を超えると無効" do
      book = build(:book, publisher: "出版社" * 17)
      expect(book).not_to be_valid
      expect(book.errors[:publisher]).to include(": 出版社は50文字以内で入力してください")
    end

    it "ページ数が負の数だと無効" do
      book = build(:book, page: -10)
      expect(book).not_to be_valid
      expect(book.errors[:page]).to include(": ページ数は50560ページ以下で入力してください")
    end

    it "ページ数が50561以上だと無効" do
      book = build(:book, page: 50561)
      expect(book).not_to be_valid
    end

    it "金額が0円以下だと無効" do
      book = build(:book, price: 0)
      expect(book).not_to be_valid
      expect(book.errors[:price]).to include(": 金額は1円以上100万円以下で指定してください")
    end

    it "金額が100万円を超えると無効" do
      book = build(:book, price: 1_000_001)
      expect(book).not_to be_valid
    end

    it "ISBNが14桁だと無効（13文字以内）" do
      book = build(:book, isbn: "12345678901234")
      expect(book).not_to be_valid
      expect(book.errors[:isbn]).to include(": ISBNは数字とXのみで13文字以内で入力してください")
    end

    it "ISBNに英字や記号が含まれると無効（X以外）" do
      book = build(:book, isbn: "9781234abc$")
      expect(book).not_to be_valid
    end

    it "ISBNがXを含み13文字以内なら有効" do
      book = build(:book, isbn: "123456789X")
      expect(book).to be_valid
    end
    it "ISBNが重複する場合は無効（同じユーザー内）" do
      user = create(:user)
      create(:book, user: user, isbn: "9781234567890")
      duplicate = build(:book, user: user, isbn: "9781234567890")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:isbn]).to include(": この書籍は本棚に登録済みです")
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
    it "ユーザーに属していること" do
      is_expected.to belong_to(:user)
    end

    it "メモを複数所有し、親が削除されるとメモも削除されること" do
      is_expected.to have_many(:memos).dependent(:destroy)
    end

    it "画像を複数所有し、親が削除されると画像も削除されること" do
      is_expected.to have_many(:images).dependent(:destroy)
    end

    it "book_cover_s3 が Active Storage のアタッチメントとして使用可能であること" do
      expect(Book.new).to respond_to(:book_cover_s3)
    end
  end

  describe "タグ機能" do
    it "タグを付けられる" do
      user = create(:user)
      book = create(:book, user: user)

      tag1 = create(:user_tag, name: "哲学", user: user)
      tag2 = create(:user_tag, name: "小説", user: user)

      # Bookにタグを付与（BookTagAssignment作成）
      book.book_tag_assignments.create!(user_tag: tag1, user: user)
      book.book_tag_assignments.create!(user_tag: tag2, user: user)

      # 検証：bookがそのタグを持っているか
      tag_names = book.book_tag_assignments.includes(:user_tag).map { |a| a.user_tag.name }

      expect(tag_names).to include("哲学", "小説")
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
