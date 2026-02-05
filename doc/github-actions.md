# GitHub Actions の構成

PR / push で動くワークフローと、失敗時にどこを見るかをまとめています。ツールの役割や選定は [github-actions-tools.md](github-actions-tools.md) を参照してください。

## PR・push で動くワークフロー一覧

`main` への push または `main` 向け PR で動くのは次の 2 本です。

| ワークフロー | 役割 |
|-------------|------|
| **CI** (`.github/workflows/ci.yml`) | 品質チェックとテスト（Lint + RSpec） |
| **Security** (`.github/workflows/security.yml`) | セキュリティスキャン（Hadolint, OSV-Scanner, Semgrep, Trivy, Scorecard） |

このほか、トリガーが異なるワークフローがあります。

| ワークフロー | トリガー | 役割 |
|-------------|----------|------|
| Dependabot auto-merge | Dependabot の PR / CI 完了時 | パッチ更新 PR に auto-merge を有効化し、CI 通過後に即マージ |
| Fly Deploy | push to main（パスフィルタあり） | 本番デプロイ |
| Fly Machines Schedule | スケジュール / 手動 | マシンの夜間停止・朝起動 |
| Upload Vite assets to R2 | push to main（フロント関連パスのみ） | R2 へアセットアップロード |

## CI ワークフローのジョブ名の意味

CI を開いたときに表示されるジョブ名は、次のプレフィックスで役割が分かります。

- **deps -** … 依存関係の健全性チェック
- **lint -** … 静的解析・スタイル（マージ前に通す想定）
- **test -** … テスト（RSpec）

| ジョブ名 | 内容 |
|----------|------|
| deps - Gemfile deprecations | `bin/check-gemfile-deprecations`（Bundler 非推奨の有無） |
| lint - RuboCop | `bin/rubocop`（Ruby スタイル・品質） |
| lint - Brakeman | `bin/brakeman`（Rails 向けセキュリティ静的解析） |
| deps - bundler-audit | `bundler-audit`（Gem の既知脆弱性） |
| test - RSpec | RSpec 全体（中で fast / system / gate に分かれる） |
| test - RSpec fast (1/4) ～ (4/4) | spec/system 以外の並列実行 |
| test - RSpec system (1/2) ～ (2/2) | spec/system の並列実行 |
| test - RSpec gate | fast と system の結果を集約し、失敗時はここで失敗する |

## Security ワークフローのジョブ名の意味

- **security -** … セキュリティスキャン。結果は Security > Code scanning に表示されます。

| ジョブ名 | 内容 |
|----------|------|
| security - Hadolint | Dockerfile のベストプラクティスチェック |
| security - OSV-Scanner (push/schedule) | 依存関係の脆弱性スキャン（push または schedule 時） |
| security - OSV-Scanner (PR) | 上記の PR 用 |
| security - Semgrep | ルールベース SAST |
| security - Trivy | コンテナイメージの脆弱性スキャン |
| security - Scorecard | サプライチェーン・リポジトリ健全性スコア |

## 失敗時に見る場所

### CI が失敗したとき

1. **Actions** タブで、失敗した **CI** の Run を開く。
2. 赤くなっているジョブをクリックする。
3. ジョブ名で種類を判断する。
   - **deps - Gemfile deprecations** で失敗 → Bundler の非推奨が出ている。Gemfile / 依存の見直し。
   - **lint - RuboCop** で失敗 → 該当ファイルのスタイル・指摘を修正。`bin/rubocop -a` で自動修正できる場合あり。
   - **lint - Brakeman** で失敗 → ログの指摘箇所を確認し、脆弱性対応または false positive の除外。
   - **deps - bundler-audit** で失敗 → 指摘された gem のアップデートまたは `bundle audit update` 後の再確認。
   - **test - RSpec fast (n/4)** または **test - RSpec system (n/2)** で失敗 → 該当ジョブのログ内で失敗した spec ファイル・行を確認。スクリーンショットは **test - RSpec system** 失敗時に Artifact に上がる場合あり。
   - **test - RSpec gate** で失敗 → 実際に失敗しているのは fast または system のいずれか。上記の fast / system のジョブログを確認する。

### Security が失敗したとき

1. **Actions** タブで、失敗した **Security** の Run を開く。
2. 赤くなっている **security - ○○** ジョブをクリックし、ログで原因を確認する。
3. アラートの詳細は **Security** タブ > **Code scanning** でも確認できる。

### ローカルで再現したいとき

- Lint 系: `bin/check-gemfile-deprecations`, `bin/rubocop`, `bin/brakeman`, `bundle exec bundler-audit check --update` をローカルで実行。
- テスト: `bundle exec rspec` または対象 spec のみ実行（[tests.instructions.md](../.github/instructions/tests.instructions.md) 参照）。
