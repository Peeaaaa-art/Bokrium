# 開発環境ガイド

## Docker環境での起動

### 基本コマンド

```bash
# サーバー起動
docker compose up web

# マイグレーション実行
docker compose run --rm web bundle exec rails db:migrate

# テスト実行
docker compose run --rm web bundle exec rspec

# コンソール
docker compose run --rm web bundle exec rails console
```

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

## Git Hooks

### pre-commit フック

コミット前に自動的にテストを実行するpre-commitフックが設定されています。テストが失敗した場合、コミットは中断されます。

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
# Pre-commit hook for running tests before commit

set -e

echo "🧪 Running tests before commit..."

# Docker環境でRSpecを実行
if docker compose run --rm web bundle exec rspec; then
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
