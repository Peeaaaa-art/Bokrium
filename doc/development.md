# 開発環境ガイド

## Docker環境での起動

### 基本コマンド

```bash
# サーバー起動
docker compose up web

# マイグレーション実行
docker compose run --rm web bundle exec rails db:migrate

# テスト実行（必ず RAILS_ENV=test を渡す。初回は下記「テスト用 DB の準備」を先に実行）
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec

# コンソール
docker compose run --rm web bundle exec rails console
```

**テスト用 DB の準備（Docker でテストする初回のみ）**

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rails db:create db:schema:load
```

### テスト実行について

- **Docker で実行する**: `docker compose run --rm -e RAILS_ENV=test web bundle exec rspec` で実行。**RAILS_ENV=test を付けないと development で動いてテストが失敗します。** コンテナには `GUEST_USER_EMAIL` と `LINE_CHANNEL_TOKEN` のデフォルトが入っているので、`.env.test` がコンテナ内で読めなくてもテストは通る想定です。
- **ローカルで `bundle exec rspec` する場合**: PostgreSQL がローカルに必要。`database.yml` のデフォルトはユーザー `postgres` なので、macOS などで「role "postgres" does not exist」と出る場合は、PostgreSQL に `postgres` ロールを作成するか、`DATABASE_USERNAME` に自ユーザーを指定して実行する（例: `DATABASE_USERNAME=$(whoami) bundle exec rspec`）。

### ローカル Postgres でテストする手順

Docker ではなくローカルの PostgreSQL で RSpec を回す場合の最小手順。

1. **PostgreSQL を起動**（Homebrew なら `brew services start postgresql@16` など）
2. **postgres ロールがない場合**  
   macOS の Homebrew Postgres などでは `postgres` ロールが無いことが多い。そのときは **すべてのコマンド** に `DATABASE_USERNAME=$(whoami)` を付ける（DB 作成もテスト実行も同じユーザーで繋ぐ）。
3. **テスト用 DB を用意**（初回のみ）  
   ```bash
   DATABASE_USERNAME=$(whoami) RAILS_ENV=test bundle exec rails db:create db:schema:load
   ```  
   （postgres ロールがある環境なら `RAILS_ENV=test bundle exec rails db:create db:schema:load` でよい）
4. **`.env.test` をプロジェクトルートに置く**  
   `GUEST_USER_EMAIL=guest@example.com` など、テストで使うメールアドレスを1行で書く。
5. **テスト実行**  
   ```bash
   DATABASE_USERNAME=$(whoami) bundle exec rspec
   ```  
   （postgres で繋ぐ環境なら `bundle exec rspec` でよい）

### Docker でテストが通らないときの確認

- **RAILS_ENV=test を付けているか**  
  `docker compose run --rm -e RAILS_ENV=test web bundle exec rspec` のように **-e RAILS_ENV=test** が必須です。付けないと development で動き、テスト用 DB に繋がらず失敗します。
- **テスト用 DB を作成したか**  
  初回は `docker compose run --rm -e RAILS_ENV=test web bundle exec rails db:create db:schema:load` を実行してください。
- コンテナには `GUEST_USER_EMAIL` と `LINE_CHANNEL_TOKEN` のデフォルトが入っているため、`.env.test` がマウントされていなくてもテストは動く想定です。`BooksQuery` は DB に `ja-x-icu` が無い環境でもフォールバックするため、Docker の Postgres でそのまま通ります。

### 初回セットアップ

```bash
# 依存関係のインストール
bundle install
npm install

# データベースのセットアップ
docker compose run --rm web bundle exec rails db:setup

# 開発サーバーの起動
bin/dev
```

### ローカルで RSpec（特に system spec）を実行する場合

Docker を使わずにローカルで `bundle exec rspec` を実行する場合、次が必要です。

- **libvips**  
  画像のリサイズ（ActiveStorage の variant / image_processing）で使用。書籍詳細や画像モーダルを開く spec で `Could not open library 'vips.42'` となる場合は未インストール。  
  - **macOS（Homebrew）**: `brew install vips`

- **Playwright ブラウザ（system spec 用）**  
  system spec のドライバに Playwright（Chromium）を使用しています。初回のみブラウザのインストールが必要です。  
  - **ローカル（Docker なし）**: `npx playwright install chromium`（`playwright` は npm 経由のため `npx` が必要です）  
  - **Docker (Dockerfile.dev)**: イメージビルド時に Chromium をインストールしています。既存イメージでエラーになる場合は `docker compose run web npx playwright install --with-deps chromium` を一度実行するか、イメージを再ビルドしてください。

## Git Hooks

### pre-commit フック

コミット前に自動的にRubocopとテストを実行するpre-commitフックが設定されています。Rubocopまたはテストが失敗した場合、コミットは中断されます。

#### フックの無効化

緊急時やCI環境など、フックをスキップしたい場合:

```bash
git commit --no-verify -m "commit message"
```

#### フックスクリプトの場所

`.git/hooks/pre-commit`

#### フックの仕組み

```bash
#!/bin/bash
# Pre-commit hook for running linter and tests before commit

set -e

echo "🔍 Running RuboCop..."

# Docker環境でRuboCopを実行（進捗表示形式）
if ! docker compose run --rm web bundle exec rubocop --format progress; then
  echo "❌ RuboCop failed! Please fix the linting errors before committing."
  exit 1
fi

echo "✅ RuboCop passed!"
echo ""
echo "🧪 Running tests..."

# Docker環境でRSpecを実行（RAILS_ENV=test 必須・進捗表示形式）
if docker compose run --rm -e RAILS_ENV=test web bundle exec rspec --format progress; then
  echo "✅ All tests passed! Proceeding with commit."
  exit 0
else
  echo "❌ Tests failed! Please fix the failing tests before committing."
  exit 1
fi
```

## テスト実行

詳細なテスト作成ガイドラインは [.github/instructions/tests.instructions.md](../.github/instructions/tests.instructions.md) を参照してください。

### 全テストの実行

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec
```

### 特定のテストファイルを実行

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec spec/models/book_spec.rb
```

### 特定の行のテストを実行

```bash
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec spec/models/book_spec.rb:10
```

## コード品質チェック

### RuboCop

```bash
docker compose run --rm web bundle exec rubocop
```

### Brakeman（セキュリティチェック）

```bash
docker compose run --rm web bundle exec brakeman
```

### Bullet（N+1クエリ検出）

開発環境でサーバーを起動すると自動的に有効になります。

## トラブルシューティング

### Dockerコンテナが起動しない

```bash
# コンテナとボリュームを削除して再構築
docker compose down -v
docker compose build --no-cache
docker compose up web
```

### データベース接続エラー

```bash
# データベースコンテナの再起動
docker compose restart db

# データベースの再作成
docker compose run --rm web bundle exec rails db:drop db:create db:migrate
```

### gemの依存関係エラー

```bash
# Bundlerのキャッシュをクリア
docker compose run --rm web bundle clean --force
docker compose run --rm web bundle install
```
