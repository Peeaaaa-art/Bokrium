# Bokrium - GitHub Copilot Instructions

## プロジェクト概要

Bokriumは、読書記録を管理するRailsアプリケーションです。

- **フレームワーク**: Ruby on Rails 8.1
- **Ruby バージョン**: 3.4.3
- **主要技術スタック**:
  - フロントエンド: Turbo Rails, Vite, ViewComponent
  - データベース: PostgreSQL
  - 認証: Devise, OmniAuth (LINE)
  - テスト: RSpec, FactoryBot, Capybara
  - 開発環境: Docker Compose

## コーディング規約

### Ruby/Rails

- RuboCopのルールに従う（rubocop-rails-omakase）
- Rails 8のベストプラクティスを優先
- Service Objectパターンを活用（`app/services/`）
- Presenterパターンを活用（`app/presenters/`）
- Queryパターンを活用（`app/queries/`）
- ViewComponentを積極的に使用

### コード品質

- BulletでのN+1クエリ検出を重視
- Brakeman でのセキュリティチェックを実施
- i18n対応を徹底（ja/enのlocaleファイルを使用）

## テストについて

詳細は `.github/instructions/tests.instructions.md` を参照してください。

## 開発コマンド

### Docker環境

```bash
# サーバー起動
docker compose up web

# マイグレーション実行
docker compose run --rm web bundle exec rails db:migrate

# テスト実行（RAILS_ENV=test 必須）
docker compose run --rm -e RAILS_ENV=test web bundle exec rspec

# コンソール
docker compose run --rm web bundle exec rails console
```

### ローカル開発

```bash
# 開発サーバー起動（Procfile.dev使用）
bin/dev
```

## 重要な注意点

- 外部HTTPリクエストはWebMockで遮断（テスト環境）
- WebAuthn認証を使用
- LINE連携機能あり
- Stripe決済機能あり
- Rakuten Web Service APIを使用
- 画像処理にActiveStorageとimage_processingを使用

## ディレクトリ構成の特徴

- `app/components/`: ViewComponentファイル
- `app/frontend/`: Vite管理のフロントエンドファイル
- `app/presenters/`: Presenterパターンの実装
- `app/queries/`: 複雑なクエリロジック
- `app/services/`: ビジネスロジック
- `spec/`: RSpecテストファイル（requestsベースを推奨）
