# テスト作成ガイドライン - RSpec

## 基本方針

- **テストファースト（原則）**: 重要な機能や複雑なビジネスロジックでは先にテストを書く。小さな修正やスパイク的な実装では柔軟に対応可
- **カバレッジ**: 重要なビジネスロジック、変更頻度が高い箇所、バグが致命的になる部分は必ずテストする
- **速度**: 高速に実行できるテストを優先（System specは必要最小限に）
- **可読性**: テストコードも本番コード同様、読みやすさを重視

## テストの種類と使い分け

### 1. Model Spec (`spec/models/`)

モデルのバリデーション、関連、スコープ、メソッドをテストします。

```ruby
RSpec.describe Book, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:memos).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:isbn).is_equal_to(13) }
  end

  describe '#published_recently?' do
    it '30日以内に出版された本はtrueを返す' do
      book = create(:book, published_at: 20.days.ago)
      expect(book.published_recently?).to be true
    end

    it '31日以上前に出版された本はfalseを返す' do
      book = create(:book, published_at: 40.days.ago)
      expect(book.published_recently?).to be false
    end
  end
end
```

**ポイント**:
- Shoulda Matchersを活用
- ファクトリを使ってテストデータを作成
- 1つのexampleで1つのことだけをテスト

### 2. Request Spec (`spec/requests/`)

**推奨**: コントローラーのテストはRequest Specで行います。

```ruby
RSpec.describe 'Books', type: :request do
  let(:user) { create(:user) }
  let(:book) { create(:book, user: user) }

  before do
    sign_in user
  end

  describe 'GET /books' do
    it '本の一覧が表示される' do
      get books_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /books' do
    context '有効なパラメータの場合' do
      let(:valid_params) { { book: attributes_for(:book) } }

      it '本が作成される' do
        expect {
          post books_path, params: valid_params
        }.to change(Book, :count).by(1)
      end

      it '本の詳細ページにリダイレクトされる' do
        post books_path, params: valid_params
        expect(response).to redirect_to(book_path(Book.last))
      end
    end

    context '無効なパラメータの場合' do
      let(:invalid_params) { { book: attributes_for(:book, title: '') } }

      it '本が作成されない' do
        expect {
          post books_path, params: invalid_params
        }.not_to change(Book, :count)
      end

      it 'フォームが再表示される' do
        post books_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /books/:id' do
    it '本が削除される' do
      book # let!ではないので先に作成
      expect {
        delete book_path(book)
      }.to change(Book, :count).by(-1)
    end
  end
end
```

**ポイント**:
- `sign_in user` でDevise認証をシミュレート
- `context` でテストケースを論理的にグループ化
- HTTPステータスコードを確認
- データの変更は `change` マッチャーで検証

### 3. System Spec (`spec/system/`)

ブラウザ操作を含むエンドツーエンドテスト。必要最小限に。

```ruby
RSpec.describe '書籍登録', type: :system do
  let(:user) { create(:user) }

  before do
    sign_in user
    driven_by(:selenium_chrome_headless)
  end

  it 'ユーザーが新しい本を登録できる' do
    visit new_book_path

    fill_in '書籍名', with: '吾輩は猫である'
    fill_in 'ISBN', with: '9784101010014'
    click_button '登録する'

    expect(page).to have_content '本を登録しました'
    expect(page).to have_content '吾輩は猫である'
  end
end
```

**ポイント**:
- JavaScriptが必要な機能のみSystem Specで
- 遅いので最小限に留める
- ハッピーパスを中心にテスト

### 4. Service Spec (`spec/services/`)

Service Objectのロジックをテストします。

```ruby
RSpec.describe Books::CreateFromIsbnService do
  describe '#call' do
    let(:isbn) { '9784101010014' }
    let(:user) { create(:user) }
    let(:service) { described_class.new(isbn: isbn, user: user) }

    context 'ISBNが有効な場合' do
      before do
        stub_request(:get, %r{https://api.rakuten.co.jp/.*})
          .to_return(status: 200, body: rakuten_api_response.to_json)
      end

      it '本が作成される' do
        expect {
          service.call
        }.to change(Book, :count).by(1)
      end

      it 'Rakuten APIから取得したタイトルが設定される' do
        book = service.call
        expect(book.title).to eq '吾輩は猫である'
      end
    end

    context 'ISBNが無効な場合' do
      let(:isbn) { 'invalid' }

      it '本が作成されない' do
        expect {
          service.call
        }.not_to change(Book, :count)
      end

      it 'nilを返す' do
        expect(service.call).to be_nil
      end
    end
  end
end
```

**ポイント**:
- WebMockで外部API呼び出しをスタブ
- 正常系と異常系の両方をテスト
- `described_class` を使用

### 5. Component Spec (`spec/components/`)

ViewComponentのテストを行います。

```ruby
RSpec.describe Books::CardComponent, type: :component do
  let(:book) { create(:book, title: 'テスト本', author: '夏目漱石') }
  let(:component) { described_class.new(book: book) }

  it 'タイトルが表示される' do
    render_inline(component)
    expect(page).to have_content 'テスト本'
  end

  it '著者名が表示される' do
    render_inline(component)
    expect(page).to have_content '夏目漱石'
  end

  context '画像がある場合' do
    before do
      book.image.attach(io: File.open('spec/fixtures/files/book_cover.jpg'), filename: 'book_cover.jpg')
    end

    it '画像が表示される' do
      render_inline(component)
      expect(page).to have_css('img[alt="テスト本"]')
    end
  end
end
```

### 6. Query Spec (`spec/queries/`)

複雑なクエリロジックをテストします。

```ruby
RSpec.describe BooksQuery do
  describe '#call' do
    let(:user) { create(:user) }
    let(:query) { described_class.new(user: user) }

    it 'ユーザーの本のみを返す' do
      user_book = create(:book, user: user)
      other_book = create(:book)
      
      expect(query.call).to include(user_book)
      expect(query.call).not_to include(other_book)
    end

    context '検索キーワードが指定された場合' do
      it 'タイトルで絞り込まれる' do
        matching_book = create(:book, user: user, title: '吾輩は猫である')
        non_matching_book = create(:book, user: user, title: '坊っちゃん')
        
        results = described_class.new(user: user, keyword: '猫').call
        expect(results).to include(matching_book)
        expect(results).not_to include(non_matching_book)
      end
    end
  end
end
```

## FactoryBotの使い方

### ファクトリ定義 (`spec/factories/`)

```ruby
FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "テスト本#{n}" }
    author { '夏目漱石' }
    sequence(:isbn) { |n| format('978410101%04d', n) }
    published_at { 1.year.ago }
    association :user

    trait :with_memo do
      after(:create) do |book|
        create(:memo, book: book)
      end
    end

    trait :published_recently do
      published_at { 1.week.ago }
    end

    trait :with_image do
      after(:build) do |book|
        book.image.attach(
          io: File.open(Rails.root.join('spec/fixtures/files/book_cover.jpg')),
          filename: 'book_cover.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
  end
end
```

### ファクトリの使用例

```ruby
# 基本的な使い方
book = create(:book)                           # DBに保存
book = build(:book)                            # メモリ上のみ（保存しない）
attributes = attributes_for(:book)             # ハッシュで取得

# 属性をオーバーライド
book = create(:book, title: '特定のタイトル')

# トレイトを使用
book = create(:book, :with_memo, :published_recently)

# 複数作成
books = create_list(:book, 3, user: user)

# 関連を明示的に指定
user = create(:user)
book = create(:book, user: user)
```

## テスト実行

### Docker環境での実行

```bash
# 全テスト実行
docker compose run --rm web bundle exec rspec

# 特定のファイルを実行
docker compose run --rm web bundle exec rspec spec/models/book_spec.rb

# 特定の行のテストを実行
docker compose run --rm web bundle exec rspec spec/models/book_spec.rb:10

# タグで絞り込み実行
docker compose run --rm web bundle exec rspec --tag focus
```

### テストの並列実行（高速化）

`parallel_tests` を使うと RSpec を並列実行して高速化できます。

**1. Gemfile に gem を追加（development/test グループ）**

```ruby
group :development, :test do
  gem 'parallel_tests'
end
```

**2. セットアップ**

```bash
bundle install
bundle exec rake parallel:setup   # 初回のみ: DB を並列用に複製
```

**3. 並列実行**

```bash
# Docker の場合
docker compose run --rm web bundle exec rake parallel:spec

# ローカルの場合
bundle exec rake parallel:spec
```

`parallel_rspec` を使う場合は、`gem 'parallel_rspec'` を追加したうえで `bundle exec parallel_rspec spec` で実行できます。

## よくあるパターン

### 外部APIのスタブ

```ruby
before do
  stub_request(:get, 'https://api.example.com/books')
    .with(query: { isbn: '9784101010014' })
    .to_return(
      status: 200,
      body: { title: 'テスト本', author: '著者名' }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
end
```

### 時間に依存するテスト

```ruby
it '翌日になると期限切れになる' do
  book = create(:book, deadline: Date.tomorrow)
  
  travel_to(2.days.from_now) do
    expect(book.expired?).to be true
  end
end
```

### ファイルアップロードのテスト

```ruby
it '画像をアップロードできる' do
  file = fixture_file_upload('spec/fixtures/files/book_cover.jpg', 'image/jpeg')
  
  post books_path, params: { book: { title: 'テスト本', image: file } }
  
  expect(Book.last.image).to be_attached
end
```

### ジョブのテスト

```ruby
it 'メール送信ジョブがキューに追加される' do
  expect {
    book.notify_followers
  }.to have_enqueued_job(NotificationMailerJob)
end
```

## アンチパターン（避けるべきこと）

❌ **テストでsleep使用**
```ruby
# 悪い例
sleep 2
expect(page).to have_content '読み込み完了'
```

✅ **Capybaraの待機を使用**
```ruby
# 良い例
expect(page).to have_content('読み込み完了', wait: 5)
```

❌ **過度なモック使用**
```ruby
# 悪い例 - 実際の振る舞いをテストしていない
allow(book).to receive(:save).and_return(true)
```

✅ **実際のオブジェクトを使用**
```ruby
# 良い例
expect { book.save }.to change(Book, :count).by(1)
```

❌ **テストの相互依存**
```ruby
# 悪い例 - 実行順序に依存
it 'ユーザーを作成' do
  @user = create(:user)
end

it 'ユーザーの本を作成' do
  create(:book, user: @user) # @userが存在することに依存
end
```

✅ **独立したテスト**
```ruby
# 良い例
it 'ユーザーの本を作成' do
  user = create(:user)
  book = create(:book, user: user)
  expect(book.user).to eq user
end
```

## Copilotへの指示例

テストを作成する際は、以下のように指示してください：

- 「BooksControllerのcreateアクションのrequest specを作成して」
- 「BookモデルのvalidationとassociationのテストをShouldaMatchersで書いて」
- 「Books::CardComponentのcomponent specを作成して、画像の有無で場合分けして」
- 「ISBN検索サービスのテストを作成して、Rakuten APIはWebMockでスタブして」
- 「書籍一覧のsystem specを書いて、検索とフィルタリングをテストして」

## ヘルパーメソッド

プロジェクトで使用可能なヘルパー：

- `sign_in user` - Devise認証（request/system spec）
- `guest_user_helper` - ゲストユーザー関連（GuestUserHelper）
- `webauthn_helper` - WebAuthn認証関連（WebAuthnHelper）

## テストカバレッジ

重要度の高い順：

1. **必須**: Service Objects、Model（ビジネスロジック）
2. **推奨**: Request Specs（コントローラー）、Query Objects
3. **オプション**: ViewComponents、System Specs（重要なユーザーフロー）

---

**テストは仕様書であり、ドキュメントです。** 
将来の自分や他の開発者が読んでも理解できる、明確で意図が伝わるテストを書きましょう。
