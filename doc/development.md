# 開発環境ガイド

## 推奨: Docker + 1Password CLI で起動

開発環境の秘密値は `.env` に実値を書かず、`config/env/.env.1password` の `op://...` 参照を使って注入します。`op` 未ログイン時は起動を止めます（フォールバックなし）。
`bin/docker-op` はフロント挙動を安定させるため、`RACK_ENV/NODE_ENV/VITE_RUBY_ENV` を `development` に固定して実行します。

### 初回セットアップ

```bash
# 1Password CLI にサインイン
op signin

# イメージビルド（初回 or 依存変更時）
bin/docker-op build web

# DB 準備
bin/docker-op run --rm web bundle exec rails db:prepare
```

### 通常起動

```bash
# サーバー起動（Rails + Vite）
bin/docker-op up web
```

- **Rails**: http://localhost:3000
- **Vite 開発サーバー**: ポート 3036

### 日常コマンド

```bash
# マイグレーション
bin/docker-op run --rm web bundle exec rails db:migrate

# テスト
bin/docker-op run --rm web bundle exec rspec

# コンソール
bin/docker-op run --rm web bundle exec rails console
```

### ホットリロード

- **Rails（Ruby / ERB など）**: コード保存で自動リロード。
- **フロント（Vite / JS / CSS）**: `app/frontend` 変更は HMR で反映。

### 互換運用（非推奨）

`.env` 実値方式は互換のため残していますが、基本運用は `bin/docker-op` を使用してください。

## ローカルで bin/dev する場合（補助導線）

Rails をホストで動かす場合も、`op run` で環境変数を注入してください。

```bash
op signin
bin/op-run bin/dev
```

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
if ! bin/docker-op run --rm web bundle exec rubocop --format progress; then
  echo "❌ RuboCop failed! Please fix the linting errors before committing."
  exit 1
fi

echo "✅ RuboCop passed!"
echo ""
echo "🧪 Running tests..."

# Docker環境でRSpecを実行（進捗表示形式）
if bin/docker-op run --rm web bundle exec rspec --format progress; then
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
bin/docker-op run --rm web bundle exec rspec
```

### 特定のテストファイルを実行

```bash
bin/docker-op run --rm web bundle exec rspec spec/models/book_spec.rb
```

### 特定の行のテストを実行

```bash
bin/docker-op run --rm web bundle exec rspec spec/models/book_spec.rb:10
```

## コード品質チェック

### RuboCop

```bash
bin/docker-op run --rm web bundle exec rubocop
```

### Brakeman（セキュリティチェック）

```bash
bin/docker-op run --rm web bundle exec brakeman
```

### Bullet（N+1クエリ検出）

開発環境でサーバーを起動すると自動的に有効になります。

## トラブルシューティング

### Dockerコンテナが起動しない

```bash
# コンテナとボリュームを削除して再構築
bin/docker-op down -v
bin/docker-op build --no-cache
bin/docker-op up web
```

### データベース接続エラー

```bash
# データベースコンテナの再起動
bin/docker-op restart db

# データベースの再作成
bin/docker-op run --rm web bundle exec rails db:drop db:create db:migrate
```

### gemの依存関係エラー

```bash
# Bundlerのキャッシュをクリア
bin/docker-op run --rm web bundle clean --force
bin/docker-op run --rm web bundle install
```
