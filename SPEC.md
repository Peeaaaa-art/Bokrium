# Bokrium 仕様書

## 1. プロジェクト概要
### 1.1 サービス概要
読書で得た知識を記録し、見返し、実践的に活用することを目的とした読書管理アプリケーション。書籍の登録、メモ、タグ付け、公開設定、ランダムなメモ通知などの機能を提供する。

- **コード根拠**: `README.md`

### 1.2 目的・背景
- **目的**: 読書を「知識として蓄積し、身体化する」こと。
- **想定ユーザー**:
    - 読んだ内容を活かせていないと感じる人
    - 蔵書を整理・把握したい人
    - 読書メモを見返したい人
- **主要ユースケース**:
    - スマートフォンのカメラで書籍のバーコードをスキャンして蔵書を登録する。
    - 書籍にメモや画像を紐づけて保存する。
    - タグ付けやステータス（読みたい/読書中/読了）で本棚を整理する。
    - 過去のメモをランダムにLINEで受け取り、知識を再確認する。
    - メモを公開し、他者と共有する。

- **コード根拠**: `README.md`

### 1.3 開発環境・技術スタック
- **フレームワーク**: Ruby on Rails 8.1.0
- **Rubyバージョン**: 3.4.3
- **フロントエンド**: Vite, Turbo Rails, Stimulus, React (Tiptapエディタ部分), Bootstrap
- **データベース**: PostgreSQL, pg_search, pg_trgm
- **認証**: Devise, OmniAuth (LINE), WebAuthn (Passkey)
- **画像ストレージ**: Active Storage, Cloudflare R2
- **決済**: Stripe
- **通知**: LINE Messaging API, Action Mailer
- **テスト**: RSpec, FactoryBot, Capybara, WebMock
- **開発環境**: Docker Compose

- **コード根拠**: `Gemfile`, `package.json`, `docker-compose.yml`, `Dockerfile`

### 1.4 デプロイ環境
- **ホスティング**: Fly.io
- **データベース**: Fly.io Postgres
- **CI/CD**: （要確認: `.github/workflows` 等の設定ファイルが見当たらない）

- **コード根拠**: `fly.toml`, `config/environments/production.rb`

## 2. アーキテクチャ
### 2.1 全体構成
標準的なRuby on RailsのMVCアーキテクチャをベースに、ビジネスロジックをService, Query, Presenterオブジェクトに分離している。フロントエンドはViteで管理され、Railsと統合されている。

- **コード根拠**: ディレクトリ構成 (`app/services`, `app/queries`, `app/presenters`), `vite.config.mts`

### 2.2 フロントエンド構成（Vite + Turbo + Stimulus）
- **ビルドツール**: Vite (`vite-plugin-ruby`でRailsと連携)
- **画面遷移**: Turbo DriveによるSPAライクな画面遷移
- **動的UI**: Turbo Frames/StreamsとStimulusコントローラーによるインタラクティブなUI更新
- **リッチテキストエディタ**: メモ入力部分にReactベースのTiptapを採用
- **バーコードスキャン**: ZXing.jsライブラリをクライアントサイドで使用

- **コード根拠**: `vite.config.mts`, `package.json`, `app/frontend/entrypoints/application.js`, `app/frontend/controllers/`

### 2.3 バックエンド構成（Rails 8 + PostgreSQL）
- **Webサーバー**: Puma
- **非同期ジョブ**: （要確認: `SolidQueue`の記載があるが、`app/jobs` には `ApplicationJob` のみ）
- **キャッシュ**: Solid Cache (DBベースのキャッシュ)

- **コード根拠**: `config/puma.rb`, `config/environments/production.rb` (`config.cache_store = :solid_cache_store`)

### 2.4 インフラ構成
- **本番環境**: Fly.io (`app`, `db`の2台構成を想定)
- **画像配信**: Cloudflare R2をオリジンとし、CDN経由で配信 (`config.asset_host`)
- **リダイレクト**: `fly.io`ドメインからカスタムドメイン (`bokrium.com`) へのリダイレクト設定あり

- **コード根拠**: `fly.toml`, `config/environments/production.rb`, `config/storage.yml`

### 2.5 外部サービス連携
- **認証**: LINE Login
- **決済**: Stripe
- **通知**: LINE Messaging API, PrivateEmail (SMTP)
- **書籍情報**: openBD, 楽天ブックス, Google Books, 国立国会図書館
- **ストレージ**: Cloudflare R2

- **コード根拠**: `config/initializers/`, `app/services/`

## 3. データベース設計
### 3.1 ER図概要
- `users`を中心に`books`, `memos`, `user_tags`が紐づく。
- `books`には`memos`, `images`, `user_tags` (中間テーブル経由)が紐づく。
- 認証関連で`credentials` (Passkey), `line_users`が存在。
- 決済関連で`donations`, `monthly_supports`が存在。

### 3.2 テーブル定義
- **`users`**: ユーザー情報。Deviseによる認証カラム、LINE連携用の`auth_provider`を持つ。
- **`books`**: 書籍情報。`user`に所属。タイトル、著者、ISBN、ステータス等。
- **`memos`**: メモ情報。`user`と`book`に所属。公開設定(`visibility`)を持つ。
- **`user_tags`**: ユーザーが作成したタグ。`user`に所属。
- **`book_tag_assignments`**: `books`と`user_tags`の中間テーブル。
- **`images`**: 書籍に紐づく画像。`book`に所属。
- **`credentials`**: WebAuthn(Passkey)の認証情報。`user`に所属。
- **`line_users`**: LINE連携情報。`user`に所属。
- **`donations`**: 単発支援の記録。`user`に所属(匿名も可)。
- **`monthly_supports`**: 月額サポートの記録。`user`に所属。
- **`like_memos`**: メモへの「いいね」記録。`user`と`memo`に所属。
- **Active Storage関連**: `active_storage_blobs`, `active_storage_attachments`, `active_storage_variant_records`。

- **コード根拠**: `db/schema.rb`, `app/models/*.rb`

### 3.3 インデックス・制約
- `users.email`にユニークインデックス。
- `books.isbn`は`user_id`のスコープでユニーク。
- `memos.content`に全文検索用の`gin_trgm_ops`インデックス。
- 各テーブルの外部キーにインデックスが設定されている。

- **コード根拠**: `db/schema.rb`

### 3.4 データ整合性ルール
- `user`が削除されると、関連する`books`, `memos`, `user_tags`, `credentials`等も同時に削除される (`dependent: :destroy`)。
- `donations`の`user`は`nullify`される。

- **コード根拠**: `app/models/user.rb`

## 4. 認証・認可
### 4.1 認証方式
- **4.1.1 メール認証（Devise）**: メールアドレスとパスワードによる認証。アカウントロック、パスワードリセット機能あり。
    - **コード根拠**: `config/initializers/devise.rb`, `app/models/user.rb`
- **4.1.2 LINE OAuth**: LINEアカウントを利用したソーシャルログイン。
    - **コード根拠**: `config/initializers/devise.rb` (`config.omniauth :line`), `app/controllers/users/omniauth_callbacks_controller.rb`
- **4.1.3 WebAuthn（Passkey）**: 指紋認証や顔認証などによるパスワードレス認証。
    - **コード根拠**: `config/initializers/webauthn.rb`, `app/models/credential.rb`, `app/controllers/users/webauthn_sessions_controller.rb`

### 4.2 認証フロー
- ユーザーはメール、LINE、Passkeyのいずれかで登録・ログイン可能。
- LINEで登録した場合、初期メールアドレスは仮発行される。メールアドレスとパスワードを設定するとメール認証に切り替わる。
- `before_action :authenticate_user!` が各コントローラーでアクセス制御を行う。

- **コード根拠**: `config/routes.rb` (`devise_for`), `app/controllers/application_controller.rb`, 各コントローラー

### 4.3 パスワード関連機能
- パスワードリセット機能あり。
- パスワードの長さは6〜128文字。

- **コード根拠**: `config/initializers/devise.rb`

### 4.4 ゲストユーザー
- ログインしていないユーザー向けに、サンプルデータを持つゲストユーザー機能を提供。
- `ENV["GUEST_USER_EMAIL"]`で指定されたユーザーをゲストとして扱う。

- **コード根拠**: `app/controllers/application_controller.rb` (`guest_user`メソッド), `app/controllers/guest/`

## 5. 機能仕様
（主要機能のみ抜粋）

### 5.1 ユーザー管理
- **権限**: 全てログインユーザーのみ。
- **機能**:
    - 新規登録/ログイン/ログアウト (`devise`の各コントローラー)
    - プロフィール編集 (名前、アバター) (`UsersController#show`, `RegistrationsController#update`)
    - メール/パスワード変更 (`Users::EmailsController`, `Users::PasswordsController`)
    - Passkey登録/削除 (`Users::CredentialsController`)

- **コード根拠**: `config/routes.rb`, `app/controllers/users/`

### 5.2 書籍管理
- **権限**: ログインユーザーは自身の書籍のみ操作可能。
- **機能**:
    - **書籍登録**:
        - ISBN検索: 楽天ブックス/Google Booksから選択可能 (`SearchController#index`)
        - バーコードスキャン: ZXing.jsによるクライアントサイドスキャン (`SearchController#barcode`)
        - 非同期ISBN検索: Turbo Streamsによるリアルタイム検索結果表示 (`SearchController#search_isbn_turbo`)
        - 手動登録: フォームからの直接入力 (`BooksController#create`)
    - **書籍一覧表示**:
        - 5種類の表示モード: shelf（本棚）, spine（背表紙）, card（カード）, detail_card（詳細カード）, b_note（ノート形式） (`ViewModesController`, `BooksIndexPresenter`)
        - オートコンプリート: タイトル・著者の入力補完 (`Books::AutocompletesController`)
    - **フィルタリング/ソート**:
        - タグフィルター: 複数タグによる絞り込み (`Books::TagsController#filter`)
        - ステータスフィルター: 読みたい/読書中/読了 (`BooksQuery`)
        - メモ公開設定フィルター: only_me/link_only/public_site (`BooksQuery`)
        - ソート: 新しい順/古い順/タイトル順/著者順/メモ更新順 (`BooksQuery`)
        - フィルター状態の永続化: セッションに保存され、次回アクセス時も維持される (`BooksIndexPresenter#sync_filter_params`)
        - フィルタークリア機能 (`BooksController#clear_filters`)
    - **書籍編集**:
        - 通常編集: 詳細ページからの編集 (`BooksController#edit`, `#update`)
        - インライン編集: b_note表示モードでの行単位編集 (`Books::RowsController`)
    - **CRUD**: `BooksController`による作成、表示、編集、削除。

- **バリデーション**:
    - タイトル: 必須、最大100文字
    - 著者: 最大100文字（任意）
    - 出版社: 最大50文字（任意）
    - ページ数: 0〜50,560（任意）
    - 価格: 0〜1,000,000円（任意）
    - ISBN: ユーザーごとに一意、数字とXのみ、最大13文字（任意）
    - 書影: jpg/png/gif/webp/svg、最大5MB

- **コード根拠**: `app/controllers/books_controller.rb`, `app/controllers/search_controller.rb`, `app/controllers/view_modes_controller.rb`, `app/controllers/books/rows_controller.rb`, `app/controllers/books/tags_controller.rb`, `app/controllers/books/autocompletes_controller.rb`, `app/queries/books_query.rb`, `app/presenters/books_index_presenter.rb`, `app/services/book_apis/`, `app/models/book.rb`, `app/models/concerns/upload_validations.rb`

### 5.3 メモ機能
- **権限**: ログインユーザーは自身のメモのみ操作可能。
- **機能**:
    - **CRUD**: `MemosController`による作成、編集、削除。
    - **公開設定**: `only_me`(自分のみ), `link_only`(リンクを知る人), `public_site`(公開)の3段階。(`Memo`モデルの`VISIBILITY` enum)
    - **いいね機能**: `LikeMemosController`でいいねの作成・削除。

- **コード根拠**: `app/controllers/memos_controller.rb`, `app/models/memo.rb`

### 5.4 画像管理
- **権限**: ログインユーザーは自身の書籍に紐づく画像のみ操作可能。
- **機能**:
    - **画像アップロード**: 書籍詳細ページから複数画像をアップロード可能。Turbo Streamsで非同期更新。
    - **画像削除**: アップロードした画像を個別に削除可能。Turbo Streamsで非同期更新。
    - **書影管理**: 書籍の表紙画像（`book_cover_s3`）を個別に管理。

- **バリデーション**:
    - ファイル形式: jpg, jpeg, png, gif, webp, svg
    - ファイルサイズ: 最大5MB

- **ストレージ**: Cloudflare R2 (`cloudflare_private_r2` サービス使用)

- **コード根拠**: `app/controllers/images_controller.rb`, `app/models/image.rb`, `app/models/concerns/upload_validations.rb`

### 5.5 タグ機能
- **権限**: ログインユーザーは自身のタグのみ操作可能。
- **機能**:
    - **タグCRUD**: タグの作成、編集（名前・色）、削除 (`UserTagsController`)
    - **タグの書籍への付与・解除**: トグル方式で付与/解除を一操作で実行 (`Books::TagsController#toggle`, `BookTagToggleService`)
    - **タグによるフィルタリング**: 複数タグでの絞り込み検索 (`BooksQuery`)
    - **タグフィルターUI**: 専用のフィルターパネルを表示 (`Books::TagsController#filter`)

- **バリデーション**:
    - タグ名: 必須、ユーザーごとに一意、最大30文字
    - 色: 任意（カラーコード）

- **中間テーブル**: `book_tag_assignments` でユーザー、書籍、タグの3者を紐づけ

- **コード根拠**: `app/controllers/user_tags_controller.rb`, `app/controllers/books/tags_controller.rb`, `app/services/book_tag_toggle_service.rb`, `app/models/user_tag.rb`, `app/models/book_tag_assignment.rb`

### 5.6 通知機能
- **権限**: ログインユーザーのみ。各ユーザーが個別にON/OFF可能。

#### 5.6.1 LINE通知
- **機能**:
    - ランダムメモ配信: 毎日午前9時に、ユーザーのメモからランダムに1件を選択してLINE通知
    - 通知ON/OFF: ユーザーが個別に設定可能 (`LineNotificationsController#toggle`)
    - 手動トリガー: Webhook経由で手動実行可能（トークン認証） (`LineNotificationsController#trigger`)

- **定期実行**: `whenever` gemによるcron設定 (`config/schedule.rb`)

- **コード根拠**: `app/services/line_notification_sender.rb`, `app/controllers/line_notifications_controller.rb`, `config/schedule.rb`

#### 5.6.2 メール通知
- **機能**:
    - ランダムメモ配信: Webhook経由で実行。ユーザーのメモからランダムに1件を選択してメール送信
    - 通知ON/OFF: ユーザーが個別に設定可能 (`UsersController#toggle_email_notifications`)
    - Webhook実行: トークン認証による外部からのトリガー (`Webhooks::EmailNotificationsController`)

- **メール送信**: Action MailerのSMTP設定（PrivateEmail使用）

- **コード根拠**: `app/services/email_notification_sender.rb`, `app/mailers/memo_mailer.rb`, `app/controllers/webhooks/email_notifications_controller.rb`, `app/controllers/users_controller.rb`

### 5.7 公開機能

#### 5.7.1 公開本棚（Public Bookshelf）
- **機能**:
    - 公開メモ一覧: 全ユーザーの公開設定されたメモを一覧表示（自分のメモは除外） (`PublicBookshelfController#index`)
    - トークンベース表示: 公開メモごとに一意のトークンを生成し、URLで個別アクセス可能 (`PublicBookshelfController#show`)
    - いいね機能: 他ユーザーの公開メモに「いいね」を付与/解除 (`LikeMemosController`)

- **権限**: 一覧と詳細は未ログインでも閲覧可能。いいねはログイン必須。

- **コード根拠**: `app/controllers/public_bookshelf_controller.rb`, `app/controllers/like_memos_controller.rb`, `app/models/memo.rb` (`ensure_public_token_if_shared`, `public_url`)

#### 5.7.2 公開メモ
- **公開レベル**: 
    - `only_me` (0): 自分のみ
    - `link_only` (1): リンクを知る人のみ
    - `public_site` (2): サイトに公開（一覧に表示）

- **トークン生成**: `link_only`または`public_site`に設定すると、自動的に20文字のランダムトークンを生成

- **コード根拠**: `app/models/memo.rb` (`VISIBILITY`, `ensure_public_token_if_shared`)

#### 5.7.3 探索（Explore）機能
- **機能**:
    - 横断検索: 自分の本棚、公開メモ、ゲスト本棚を横断して検索
    - スコープ切り替え: `mine`（自分）、`public`（公開）、`guest`（ゲスト）
    - 全文検索: タイトル、著者、メモ内容を対象に検索

- **権限**: 未ログインでも公開メモとゲスト本棚は検索可能。自分の本棚検索はログイン必須。

- **コード根拠**: `app/controllers/explore_controller.rb`

### 5.8 支援機能
- **権限**: ログイン状態に関わらず支援可能。ログインユーザーの場合はユーザー情報と紐づく。
- **機能**:
    - **単発支援**: Stripe Checkoutを利用したクレジットカード決済。(`DonationsController`)
    - **月額サポート**: Stripe Subscriptionを利用したサブスクリプション。(`SubscriptionsController`)
    - **Webhook**: 決済完了・失敗などのイベントをStripe Webhookで受信し、DBを更新。(`Webhooks::StripeController`)

- **コード根拠**: `app/controllers/donations_controller.rb`, `app/controllers/subscriptions_controller.rb`, `app/controllers/webhooks/stripe_controller.rb`

### 5.9 ゲスト機能
- **目的**: 未登録ユーザーに機能を体験してもらうためのサンプルデータ表示。

#### 5.9.1 ゲストユーザー
- **設定**: `ENV["GUEST_USER_EMAIL"]`で指定されたユーザーをゲストとして扱う
- **データ**: ゲストユーザーの書籍・メモを表示（読み取り専用）

- **コード根拠**: `app/controllers/application_controller.rb` (`guest_user`メソッド)

#### 5.9.2 ゲスト本棚
- **機能**:
    - 本棚一覧: ゲストユーザーの書籍を本棚形式で表示 (`Guest::BooksController#index`)
    - 書籍詳細: ゲストユーザーの書籍詳細とメモを表示 (`Guest::BooksController#show`)
    - フィルター・ソート: 通常の本棚と同様の機能を提供
    - 表示モード切り替え: 5種類の表示モードに対応

- **権限**: 未ログインでも閲覧可能（読み取り専用）

- **コード根拠**: `app/controllers/guest/books_controller.rb`

#### 5.9.3 スターターブック（チュートリアル）
- **機能**:
    - 機能紹介: Bokriumの主要機能を解説する専用ページ
    - セクション別表示:
        - 5種類のレイアウト紹介 (`five_layouts`)
        - バーコードスキャン機能紹介 (`barcode_section`)
        - 本棚機能紹介 (`bookshelf_section`)
        - メモ機能紹介 (`memo_section`)
        - 公開機能紹介 (`public_section`)
        - ガイドブック (`guidebook_section`)

- **権限**: 未ログインでも閲覧可能

- **コード根拠**: `app/controllers/guest/starter_books_controller.rb`

### 5.10 その他

#### 5.10.1 PWA対応
- **機能**: `manifest.json`を提供し、PWA（Progressive Web App）として動作可能
- **コード根拠**: `app/controllers/pwa_controller.rb`, `config/routes.rb` (`get "/manifest.json"`)

#### 5.10.2 静的ページ
- **FAQ**: よくある質問 (`/faq`)
- **利用規約**: サービス利用規約 (`/terms`)
- **プライバシーポリシー**: 個人情報保護方針 (`/privacy`)
- **法的情報**: 特定商取引法に基づく表記等 (`/legal`)
- **お問い合わせ**: 問い合わせフォーム (`/contact`)

- **コード根拠**: `app/controllers/pages_controller.rb`, `config/routes.rb`

#### 5.10.3 ヘルスチェック
- **機能**: `/up` エンドポイントで200 OKを返す。Fly.ioのヘルスチェックに使用。
- **コード根拠**: `config/routes.rb`, `fly.toml`

#### 5.10.4 開発環境専用機能
- **Letter Opener Web**: 開発環境でのメールプレビュー機能 (`/letter_opener`)
- **コード根拠**: `config/routes.rb` (`mount LetterOpenerWeb::Engine if Rails.env.development?`)

## 6. 外部API連携
### 6.1 書籍情報取得API
- **フロー**: ISBNをキーに、openBD → 楽天ブックス → Google Books → 国会図書館の順でAPIを呼び出し、情報を取得・統合する。
- **ISBN検証**: 入力されたISBNは正規化・バリデーション・変換が行われる。
- **コード根拠**: `app/services/book_apis/`, `app/services/isbn_check/`

### 6.2 LINE連携
- **LINE Login**: OmniAuthによる認証。
- **LINE Messaging API**: ユーザーへのプッシュ通知（ランダムメモ）に使用。
- **LINE Webhook**: ユーザーからのメッセージ等を受信（現在は実装されていない模様）。
- **コード根拠**: `config/initializers/devise.rb`, `app/services/line_notification_sender.rb`, `app/controllers/line_webhooks_controller.rb`

### 6.3 Stripe連携
- **Stripe Checkout**: 単発決済、サブスクリプション開始に使用。
- **Stripe Customer Portal**: サブスクリプション管理画面へのリダイレクト。
- **Stripe Webhooks**: 決済イベントの非同期処理。
- **コード根拠**: `app/controllers/donations_controller.rb`, `app/controllers/subscriptions_controller.rb`, `app/controllers/webhooks/stripe_controller.rb`

### 6.4 Cloudflare R2
- **用途**: ユーザーアバター、書籍関連画像のストレージ。
- **設定**: `cloudflare_r2` (公開) と `cloudflare_private_r2` (非公開) の2つのサービスを設定。
- **コード根拠**: `config/storage.yml`, `app/models/book.rb`, `app/models/user.rb`

## 7. ビジネスロジック
### 7.1 Service オブジェクト
- **`BookApis::*`**: 各書籍情報APIとの通信ロジック。
- **`IsbnCheck::*`**: ISBNの検証・変換ロジック。
- **`LineNotificationSender`**: LINEで通知を送信するロジック。
- **`EmailNotificationSender`**: メール通知を送信するロジック。
- **`BookTagToggleService`**: 書籍へのタグ付与・解除のトグルロジック。

- **コード根拠**: `app/services/`

### 7.2 Query オブジェクト
- **`BooksQuery`**: 書籍一覧のフィルタリングとソートを担当。

- **コード根拠**: `app/queries/books_query.rb`

### 7.3 Presenter オブジェクト
- **`BooksIndexPresenter`**: 書籍一覧ページの表示に必要な複雑なロジックをカプセル化。

- **コード根拠**: `app/presenters/books_index_presenter.rb`

### 7.4 Model Concerns
- **`RandomSelectable`**: ランダム選択機能を提供。`random_1`（1件）と`random_9`（9件）メソッドを定義。
- **`UploadValidations`**: 画像アップロードの共通バリデーション。ファイル形式とサイズをチェック。

- **コード根拠**: `app/models/concerns/random_selectable.rb`, `app/models/concerns/upload_validations.rb`

## 8. バッチ・定期処理
### 8.1 定期実行設定
- **ツール**: `whenever` gem
- **設定ファイル**: `config/schedule.rb`
- **実行内容**: 毎日午前9時に`LineNotificationSender.send_all`を実行し、LINE通知を送信する。

- **コード根拠**: `config/schedule.rb`, `app/services/line_notification_sender.rb`

## 9. ルーティング設計
- `config/routes.rb` にて定義。
- `devise_for` で認証関連のルートを自動生成。
- `resources` を用いたRESTfulなルーティングが基本。
- `guest` 名前空間でゲストユーザー向けのルートを定義。
- `webhooks` 名前空間で外部サービスからのWebhook受信用ルートを定義。

- **コード根拠**: `config/routes.rb`

## 10. セキュリティ
- **CSRF対策**: `protect_from_forgery with: :exception` が有効。
- **認証・認可**: Deviseによる認証と、コントローラーレベルでの `before_action` によるアクセス制御。
- **SSL/TLS**: 本番環境では `force_ssl = true` により常時SSL化。
- **環境変数管理**: `dotenv-rails` を使用。重要なキーはRailsの`credentials.yml.enc`または環境変数で管理。
- **静的解析**: `Brakeman` を導入。
- **Webhook認証**: LINE通知トリガーとメール通知Webhookは、環境変数で設定されたトークンによる認証を実施。
    - `ENV["LINE_TRIGGER_TOKEN"]`: LINE通知の手動トリガー用
    - `ENV["EMAIL_CRON_TOKEN"]`: メール通知Webhook用

- **コード根拠**: `app/controllers/application_controller.rb`, `config/environments/production.rb`, `Gemfile`, `app/controllers/line_notifications_controller.rb`, `app/controllers/webhooks/email_notifications_controller.rb`

## 11. パフォーマンス
- **N+1クエリ対策**: `Bullet` を導入。`includes` を適切に使用している箇所が多数見られる (`BooksController#set_book_with_associations` 等)。
- **キャッシュ戦略**: `Solid Cache` (DBベース) を本番環境のキャッシュストアとして使用。
- **画像配信**: Cloudflare CDN経由で配信 (`config.asset_host`)。
- **全文検索**: `pg_search` を利用し、`memos.content` や `books` のタイトル・著者に対してインデックスを利用した検索を実装。

- **コード根拠**: `Gemfile`, `config/environments/production.rb`, `app/models/memo.rb`, `app/models/book.rb`

## 12. テスト
- **テスト方針**: RSpecを使用し、Model, Request, Service, Query Specが中心。
- **テストツール**: `RSpec`, `FactoryBot`, `Capybara`, `WebMock` (外部APIリクエストのスタブ)。
- **CI/CD**: （要確認: 設定ファイルが見当たらない）

- **コード根拠**: `spec/`, `.github/instructions/tests.instructions.md`

## 13. 国際化（i18n）
- **対応言語**: 日本語 (`ja`) と英語 (`en`)。デフォルトは日本語。
- **ロケールファイル**: `config/locales/` に `ja.yml`, `en.yml` を配置。Devise関連の翻訳ファイルも含む。

- **コード根拠**: `config/application.rb` (`config.i18n.default_locale = :ja`), `config/locales/`

## 14. 運用・デプロイ
- **Docker構成**: `Dockerfile` (本番用) と `Dockerfile.dev` (開発用) が存在。`docker-compose.yml` で開発環境を構築。
- **本番環境**: Fly.io。`fly.toml` にデプロイ設定、ヘルスチェック、リリース時マイグレーションコマンドが定義されている。
- **ログ管理**: 本番環境ではSTDOUTにログを出力。

- **コード根拠**: `Dockerfile`, `docker-compose.yml`, `fly.toml`

---

## 付録

### 付録A. 環境変数一覧

以下の環境変数が必要です。

#### 認証・ユーザー管理
- `GUEST_USER_EMAIL`: ゲストユーザーのメールアドレス

#### LINE連携
- `LINE_LOGIN_CHANNEL_ID`: LINE LoginのチャネルID
- `LINE_LOGIN_CHANNEL_SECRET`: LINE Loginのチャネルシークレット
- `LINE_CHANNEL_TOKEN`: LINE Messaging APIのアクセストークン
- `LINE_CHANNEL_SECRET`: LINE Messaging APIのチャネルシークレット
- `LINE_TRIGGER_TOKEN`: LINE通知の手動トリガー用トークン

#### 書籍情報API
- `RAKUTEN_APPLICATION_ID`: 楽天ブックスAPIのアプリケーションID

#### Stripe決済
- `STRIPE_SECRET_KEY`: Stripeのシークレットキー
- `STRIPE_WEBHOOK_SECRET`: Stripe Webhookのシークレット
- `STRIPE_PRICE_ID`: 月額サポートのPrice ID

#### Cloudflare R2
- `R2_ACCESS_KEY_ID`: R2のアクセスキーID
- `R2_SECRET_ACCESS_KEY`: R2のシークレットアクセスキー
- `R2_ENDPOINT`: R2のエンドポイントURL

#### メール送信
- `PRIVATE_EMAIL_PASSWORD`: メール送信用のSMTPパスワード
- `EMAIL_CRON_TOKEN`: メール通知Webhook用トークン

#### WebAuthn
- `WEBAUTHN_ORIGIN`: WebAuthnの許可オリジン（例: https://bokrium.com）
- `WEBAUTHN_RP_ID`: Relying Party ID（例: bokrium.com）

#### その他
- `APP_HOST`: アプリケーションのホストURL（通知メールのリンク生成に使用）
- `DATABASE_URL`: データベース接続URL（本番環境）
- `DIRECT_DATABASE_URL`: ダイレクトDB接続URL（Fly.ioマイグレーション用）

**コード根拠**: コード全体の`ENV[...]`参照箇所

### 付録B. バリデーション・制限事項一覧

#### Userモデル
- 名前: 最大50文字
- メール: 必須、ユニーク、RFC準拠のフォーマット
- パスワード: 6〜128文字（Passkeyのみの場合は不要）

#### Bookモデル
- タイトル: 必須、最大100文字
- 著者: 最大100文字
- 出版社: 最大50文字
- ページ数: 0〜50,560
- 価格: 0〜1,000,000円
- ISBN: ユーザーごとに一意、数字とXのみ、最大13文字
- 書影: jpg/png/gif/webp/svg、最大5MB

#### Memoモデル
- コンテンツ: 最大10,000文字
- 公開設定: only_me(0), link_only(1), public_site(2)のいずれか

#### UserTagモデル
- タグ名: 必須、ユーザーごとに一意、最大30文字

#### Imageモデル
- 画像ファイル: jpg/jpeg/png/gif/webp/svg、最大5MB

#### Credentialモデル
- external_id: 必須、ユニーク
- public_key: 必須
- sign_count: 0以上の整数

#### LikeMemoモデル
- user_id + memo_id: ユニーク（同じメモに複数回いいねできない）

#### BookTagAssignmentモデル
- book_id + user_tag_id: ユニーク（同じ書籍に同じタグを複数回付けられない）

**コード根拠**: `app/models/*.rb`、`app/models/concerns/upload_validations.rb`

---

## 未確定事項（要確認）一覧

| 項目 | 内容 | 確認方法 |
|---|---|---|
| **非同期ジョブの利用状況** | `SolidQueue`の記載はあるが、具体的なジョブの実装が少ない。メール送信などが非同期で行われているか。 | `ActionMailer`の`deliver_later`の使用状況を検索。`app/jobs/`ディレクトリを確認。 |
| **CI/CDの設定** | テストの自動実行やデプロイのパイプラインが設定されているか。 | `.github/workflows/` や `.circleci/` 等のディレクトリの有無を確認。 |
| **モニタリング・エラートラッキング** | New Relic, Sentry, Datadog等のAPMツールやエラートラッキングツールが導入されているか。 | `Gemfile`や初期化ファイル(`config/initializers/`)で関連gemの有無を確認。 |
| **バックアップ戦略** | データベースやストレージの定期的なバックアップがどのように行われているか。 | Fly.ioの管理画面や関連ドキュメント、デプロイスクリプト等を確認。コードからは判断不可。 |
| **環境変数の一覧と必須項目** | `.env.example`のようなファイルがなく、必要な環境変数の全貌が不明。 | コード全体で`ENV[...]`を検索し、一覧を作成。特に外部サービスのAPIキーやシークレットキーが必須。 |
| **既知の技術的負債** | コード内の`TODO`, `FIXME`コメントの有無。 | `grep`等で "TODO", "FIXME" を検索。 (今回の調査では見つからなかった) |
| **アクセス解析** | Google Analytics等のトラッキングコードが埋め込まれているか。 | `app/views/layouts/application.html.erb`等でトラッキング用のJavaScriptコードの有無を確認。 |
