# PR 本文（update/github-actions）

## 目的

- **CI / GitHub Actions を 2026 年頃のトレンドに合わせて整備し、セキュリティスキャンを追加する**
- 開発体験（並列・キャッシュ・権限）とセキュリティ（コード・依存・コンテナ・サプライチェーン）の両方を強化する

---

## 変更の全体像

このブランチでは次の 3 つの塊で変更を入れています。

1. **CI 基盤の整理** … RSpec 環境の共通化、Gemfile 非推奨チェック、E2E を Playwright に統一
2. **GitHub Actions の更新** … アクション v6 統一・concurrency・dependabot npm・paths 等
3. **セキュリティスキャンの追加** … CodeQL / OSV-Scanner / Trivy / Semgrep / OSSF Scorecard の導入と schedule の統一

---

## 1. CI 基盤の整理

### 意図
- RSpec（fast / system）のセットアップを 1 か所にまとめ、CI の見通しとメンテナンス性を上げる
- Gemfile の非推奨表現を早期に検知する
- システムスペックを Selenium から Playwright に移行し、軽量・高速な E2E 環境にする

### 主な変更
- **`.github/actions/setup-rspec-env`** … Ruby / Node / Postgres / Vite のセットアップを composite action に集約
- **`ci.yml`** … `setup-rspec-env` 利用、Gemfile 非推奨チェックジョブ追加、push トリガー追加
- **`bin/check-gemfile-deprecations`** … Gemfile の非推奨チェック用スクリプト
- **E2E を Playwright に統一** … `spec/support/capybara.rb` で Playwright ドライバのみにし、Selenium 用コードと `selenium-webdriver` gem を削除

---

## 2. GitHub Actions の更新

### 意図
- アクションのバージョンと権限を揃え、再現性とセキュリティを確保する
- 無駄な実行を減らし、同一ブランチの古い実行をキャンセルしてリソースを有効に使う

### 主な変更
- **checkout / setup-node を v6 に統一** … ci.yml および setup-rspec-env（認証情報まわりの改善を利用）
- **CI に concurrency 追加** … 同一ブランチで新しい run が始まったら古い run をキャンセル（`cancel-in-progress: true`）
- **dependabot.yml** … `package-ecosystem: npm` を追加（フロントの依存更新 PR を自動化）
- **fly-sleep.yml** … `setup-flyctl@master` をやめ、`@v1` + `version: "0.4.6"` で固定
- **upload-vite-assets-to-r2.yml** … フロント関連パスの変更時のみ実行する `paths` と `cache: "npm"` を追加
- **doc/github-actions-evaluation.md** … 現状評価・トレンドとのギャップ・追加候補をまとめた評価レポートを追加

---

## 3. セキュリティスキャンの追加

### 意図
- コード（CodeQL / Semgrep）、依存関係（OSV-Scanner）、コンテナ（Trivy）、サプライチェーン（OSSF Scorecard）をカバーし、Security タブで一元的に確認できるようにする
- スケジュール実行は「毎月 15 日」に統一し、実行回数と運用負荷のバランスを取る

### 主な変更
- **codeql.yml** … Ruby / JavaScript-TypeScript / Actions を CodeQL で解析。push/PR to main + 毎月 15 日 01:00 UTC
- **osv-scanner.yml** … Gemfile / package.json 等の依存関係の脆弱性スキャン。push/PR/merge_group + 毎月 15 日 02:00 UTC
- **trivy.yml** … Dockerfile からビルドしたイメージの脆弱性スキャン。push/PR to main + 毎月 15 日 01:30 UTC
- **semgrep.yml** … ルールベースの SAST（SARIF で Code scanning に表示）。workflow_dispatch、push/PR to main、毎月 15 日 03:00 UTC。Dependabot の PR ではスキップ、SEMGREP_APP_TOKEN のみ使用
- **scorecard.yml** … OSSF Scorecard（サプライチェーン・リポジトリ健全性）。branch_protection_rule、push/PR to main、毎月 15 日 04:00 UTC。checkout / upload-artifact / scorecard-action は元テンプレートの SHA ピンのまま
- **doc/github-actions-evaluation.md** … CodeQL を「Security タブで既に有効の場合は追加不要」と明記

---

## レビュー時のポイント

- **CI** … main への push / PR で、gemfile_deprecations / rubocop / brakeman / rspec_fast / rspec_system が意図どおり動くこと
- **セキュリティワークフロー** … 各 YAML のトリガー・schedule・権限が想定どおりか（fly-sleep の cron は変更していません）
- **Dependabot** … npm が有効になり、package.json 変更に対する PR が想定どおり作成されるか（マージ後しばらくして確認）
- **Semgrep** … 利用する場合は Semgrep.dev で SEMGREP_APP_TOKEN を取得し、リポジトリの Secrets に設定する必要があります

---

## マージ後に行うとよいこと

- リポジトリの **Settings > Secrets and variables > Actions** で、必要に応じて `SEMGREP_APP_TOKEN` を設定する
- **Security > Code scanning** で、CodeQL / OSV-Scanner / Trivy / Semgrep / Scorecard の結果が表示されることを確認する
