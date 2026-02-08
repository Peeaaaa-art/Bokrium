# 開発環境ガイド

## ローカルで bin/dev する場合（DB だけ Docker）

Rails はホストで動かし、PostgreSQL だけ Docker で動かす場合:

```bash
# DB コンテナだけ起動（postgres/postgres で localhost:5432）
docker compose up -d db

# 初回のみ: DB 作成とマイグレーション
bundle exec rails db:create db:migrate
# または db:setup（スキーマ＋seed まで）

# 開発サーバー起動
bin/dev
```

`config/database.yml` のデフォルトは `username: postgres`, `password: postgres` なので、Docker の db サービスとそのまま一致します。接続エラーになる場合は、PostgreSQL が起動しているか `docker compose ps` で確認してください。

## Docker環境での起動

### 基本コマンド

```bash
# サーバー起動（Rails + Vite を foreman で同時起動）
docker compose up web
```

- **Rails**: http://localhost:3000
- **Vite 開発サーバー**: ポート 3036（アセットは自動で Rails から参照されます）

その他のコマンドは `web` コンテナ内で実行します:

```bash
# マイグレーション実行
docker compose run --rm web bundle exec rails db:migrate

# テスト実行
docker compose run --rm web bundle exec rspec

# コンソール
docker compose run --rm web bundle exec rails console
```

### ホットリロード

- **Rails（Ruby / ERB など）**: コードを保存すると自動でリロードされます（開発モードのため）。
- **フロント（Vite / JS / CSS）**: `app/frontend` や関連ファイルを保存すると、Vite が即時ビルドし、ブラウザは HMR で更新されます。`docker compose up web` で foreman が Rails と Vite の両方を起動しているため、ファイル変更はそのまま反映されます。

### 初回セットアップ（Docker で全部やる場合）

```bash
# イメージビルド（Gemfile / package.json 変更時も再ビルド）
docker compose build web

# データベースのセットアップ
docker compose run --rm web bundle exec rails db:setup

# 開発サーバー起動
docker compose up web
```

`Gemfile` や `package.json` を変更したあとは `docker compose build web` を実行してから `docker compose up web` してください。

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

# Docker環境でRSpecを実行（進捗表示形式）
if docker compose run --rm web bundle exec rspec --format progress; then
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
docker compose run --rm web bundle exec rspec
```

### 特定のテストファイルを実行

```bash
docker compose run --rm web bundle exec rspec spec/models/book_spec.rb
```

### 特定の行のテストを実行

```bash
docker compose run --rm web bundle exec rspec spec/models/book_spec.rb:10
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
