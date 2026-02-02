# GitHub Actions 評価レポート（2026年2月）

## 現状の構成

| ワークフロー | トリガー | 主な内容 |
|-------------|----------|----------|
| **ci.yml** | push/PR → main | Gemfile非推奨チェック、RuboCop、Brakeman、RSpec（fast 4並列 + system 2並列）、Playwright |
| **fly-deploy.yml** | push → main（.md除外） | Fly.io デプロイ |
| **fly-sleep.yml** | cron + workflow_dispatch | 日本時間で夜停止・朝起動 |
| **upload-vite-assets-to-r2.yml** | push → main | Viteビルド → Cloudflare R2 アップロード |

**カスタムアクション:** `setup-rspec-env`（composite）で Ruby/Node/Postgres/Vite を共通セットアップ。

---

## 良い点（評価）

1. **CI 設計**
   - RSpec を fast / system に分離し、fast を 4 並列で分散（`TOTAL_NODES` / `NODE_INDEX`）している
   - 軽いジョブ（gemfile_deprecations, rubocop, brakeman）は並列で独立
   - `fail-fast: false` で全ノード結果を確認できる

2. **インフラ**
   - `ubuntu-24.04`、Postgres 16、Node 22 など新しいランタイムを使用
   - `ruby/setup-ruby` の `bundler-cache: true` でキャッシュ活用
   - デプロイに `concurrency: deploy-group` を指定して競合を防止

3. **セキュリティ**
   - `permissions: contents: read` で最小権限
   - Brakeman で静的セキュリティチェックを実施

4. **運用**
   - Fly の夜間停止でコスト最適化
   - デプロイは `.md` を paths-ignore して無駄な実行を削減

---

## 2026年トレンドとのギャップ・改善点

### 1. アクションのバージョンが混在

| ファイル | checkout | setup-node | 備考 |
|----------|----------|------------|------|
| ci.yml / setup-rspec-env | **v4** | **v4** | 古い |
| fly-deploy.yml | v6.0.1（SHAピン） | - | 良い |
| fly-sleep.yml | v6 | - | `setup-flyctl@master` は非推奨 |
| upload-vite-assets-to-r2.yml | v6 | v6 | 良い |

- **checkout v6**: 認証情報の扱いが改善（`$RUNNER_TEMP` に分離）されており、v4 → v6 への統一が推奨
- **setup-flyctl@master**: 再現性・安定性のため、`@v1` やタグ付きバージョンへのピン留めが望ましい

### 2. デプロイ・ストレージの認証（OIDC）

- **Fly.io**: 現状は `FLY_API_TOKEN`（長期トークン）を Secrets に保存。Fly.io は OIDC をサポートしており、トークンレスでデプロイする構成が 2025–2026 のトレンド
- **R2**: AWS 互換 API のため、将来的に AWS OIDC 連携で短期トークンに移行する選択肢がある

現時点では必須ではないが、「トレンドに乗る」なら OIDC 検討の価値あり。

### 3. Dependabot の対象が不足

- 現在: `bundler` と `github-actions` のみ
- **npm（package.json）が未設定**のため、フロントエンド依存関係の自動 PR が来ない

### 4. CI の concurrency

- 複数 PR が同時に main に向かうと、それぞれがフルマトリックスで走り、ランナーと時間を消費する
- `concurrency: group: ${{ github.workflow }}-${{ github.ref }}` と `cancel-in-progress: true` を付けると、同じブランチの新しい push で古い実行をキャンセルでき、2025–2026 ではよく使われるパターン

### 5. アセットアップロードの最適化

- `upload-vite-assets-to-r2.yml` は **main への push のたびに** 実行される
- `paths` で `app/frontend/**` や `package*.json`、`vite.config.*` など、フロントのみ変更時に限定すると無駄なビルド・アップロードを減らせる
- `actions/setup-node` の `cache: 'npm'` を入れると npm のキャッシュが効く

### 6. その他

- **fly-sleep.yml**: `actions/checkout@v6` は問題ないが、`setup-flyctl@master` はタグまたはコミット SHA で固定した方が安全
- **upload-vite-assets-to-r2.yml**: `npm run build` と `npm ci` の前提（`NODE_ENV` や `vite build` の有無）を README や doc に書いておくと運用しやすい

---

## 追加を検討したいアクション

### 優先度高

| アクション | 目的 | 備考 |
|------------|------|------|
| **Dependabot（npm）** | package.json の依存関係更新 PR | 設定だけで効果が大きい |
| **CI concurrency** | 同一ブランチの古い実行をキャンセル | ワークフローに数行追加するだけ |
| **checkout/setup-node を v6 に統一** | セキュリティ・一貫性 | ci.yml と setup-rspec-env を更新 |

### 優先度中

| アクション | 目的 | 備考 |
|------------|------|------|
| **CodeQL（Ruby）** | コードの脆弱性・不具合の静的解析 | リポジトリの Security タブで既に有効化済みの場合は不要 |
| **dependency-review** | PR で依存関係変更時の差分チェック | Dependabot PR で特に有用 |
| **Vite アップロードの paths 制限** | フロント変更時のみ R2 アップロード | 実行時間・コスト削減 |
| **setup-flyctl のバージョン固定** | 再現性・予測可能なデプロイ | fly-sleep / fly-deploy の両方 |

### 優先度低（任意）

| アクション | 目的 | 備考 |
|------------|------|------|
| **OIDC（Fly / R2）** | 長期トークン廃止・運用の近代化 | ドキュメント整備後に検討 |
| **reusable workflow** | Ruby セットアップの共通化 | 既に composite action で整理されているため必須ではない |
| **Slack / Teams 通知** | デプロイ失敗などの通知 | チームの運用方針次第 |

---

## 実装の優先順位（推奨）

1. **dependabot.yml に npm を追加**（即効性が高い）
2. **ci.yml の checkout を v6 にし、concurrency を追加**
3. **setup-rspec-env の checkout / setup-node を v6 に**
4. **fly-sleep の setup-flyctl をバージョン固定**
5. **upload-vite-assets-to-r2 に paths と npm cache を追加**
6. **CodeQL**: Security タブで既に有効化済みのため追加不要
7. （任意）**dependency-review を PR 用ワークフローに追加**

---

## 総評

- **現状**: CI の設計（並列・役割分担）、ランタイムの新しさ、権限の絞り込みはよくできており、実用上問題はない。
- **トレンド**: アクションの v6 統一、Dependabot の npm 追加、concurrency、OIDC の検討で「2026年のトレンドに合わせた」構成に近づく。
- **追加で効果が大きいもの**: Dependabot（npm）、CI concurrency、checkout/setup-node の v6 統一。これらから着手するのがおすすめ。
