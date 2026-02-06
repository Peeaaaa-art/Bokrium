# このアプリでの OWASP ZAP の実行方法

このドキュメントでは、Bokrium において OWASP ZAP（Baseline Scan）をどのように実行しているかを説明します。設計の背景や役割の整理は [dast-plan-review.md](dast-plan-review.md) を参照してください。

## 概要

- **ツール**: OWASP ZAP（Zed Attack Proxy）の **Baseline Scan**（`zap-baseline.py`）
- **目的**: CI 内のテスト環境（Rails アプリ）に対してパッシブスキャンを行い、セキュリティヘッダー・Cookie 設定などの**退行検知**の補助とする。本番は叩かず、認証不要の範囲で実行する。
- **実行タイミング**: **手動のみ**。GitHub Actions の「Run workflow」から DAST ワークフローを実行する（PR や push では自動では動かない）。

## 実行の流れ

### 1. ワークフローを手動で実行する

1. GitHub リポジトリの **Actions** タブを開く
2. 左メニューから **「DAST (OWASP ZAP Baseline)」** を選ぶ
3. **「Run workflow」** をクリックし、ブランチ（通常は `main`）を選んで実行

### 2. ワークフロー内で行っていること

実行元の定義は [`.github/workflows/dast.yml`](../.github/workflows/dast.yml) です。

| 順番 | 内容 |
|------|------|
| 1 | リポジトリのチェックアウト |
| 2 | **setup-rspec-env** で Ruby / Node のセットアップ、npm install、Vite ビルド、Postgres 待機、`db:prepare` まで実施（RSpec と同じ環境） |
| 3 | **Postgres** を services で起動（`postgres:16`、ポート 5432） |
| 4 | **Rails サーバー**をバックグラウンドで起動（`nohup bin/rails server -b 0.0.0.0 -p 3000`） |
| 5 | **起動待ち**: `http://localhost:3000/up` に 200 が返るまで最大 30 回×2 秒でポーリング |
| 6 | **OWASP ZAP Baseline** を Docker で実行（後述） |
| 7 | 生成された **report.html / report.json** を Artifact としてアップロード |

### 3. ZAP の実行コマンド

ZAP は公式 Docker イメージを `--network host` で動かし、runner 上の `localhost:3000` に立ち上がった Rails にアクセスします。

```bash
docker run --network host -v "${{ github.workspace }}:/zap/wrk" \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:3000 -I \
  -r /zap/wrk/report.html -J /zap/wrk/report.json
```

| 指定 | 意味 |
|------|------|
| `--network host` | コンテナから runner の localhost に届くようにする（Rails が runner 上で動いているため） |
| `-v ...:/zap/wrk` | ワークスペースを ZAP の作業ディレクトリにマウントし、レポートをリポジトリ側に書き出す |
| `-t http://localhost:3000` | スキャン対象 URL |
| `-I` | 見つかった問題を警告扱いにして終了コードを 0 のままにし、ジョブを失敗させない（レポート確認を優先） |
| `-r /zap/wrk/report.html` | HTML レポートの出力先（マウント先の絶対パスで指定） |
| `-J /zap/wrk/report.json` | JSON レポートの出力先（同上） |

ZAP ステップには `continue-on-error: true` を付けてあり、ZAP が非ゼロで終了してもワークフローは成功扱いになります。Artifact は `if-no-files-found: ignore` のため、レポートが生成されなくてもアップロードステップでは失敗しません。

### 4. 環境変数（ジョブで設定しているもの）

| 変数 | 値 | 用途 |
|------|-----|------|
| `RAILS_ENV` | test | Rails をテスト環境で起動 |
| `APP_HOST` | http://localhost:3000 | アプリの URL |
| `PORT` | 3000 | Rails の待ち受けポート |
| `LINE_CHANNEL_TOKEN` | dummy_token_for_test | テスト用のダミー（外部連携を動かさない） |
| `DATABASE_URL` | postgres://postgres:postgres@localhost:5432/test_db | Postgres 接続情報（services と整合） |

## 結果の確認

- **Actions** の当該 Run を開き、**「DAST - OWASP ZAP Baseline」** ジョブを選択する
- ジョブ完了後、**Artifacts** に **zap-baseline-report** が表示されるのでダウンロードする
- 中身の **report.html** をブラウザで開いて内容を確認する（report.json はスクリプト等で利用可能）

ターゲット（Rails）に到達できなかった場合などはレポートが生成されないことがあり、その場合は Artifact が空になるか含まれないことがあります。

## 役割と限界

- **役割**: パッシブスキャン（レスポンスヘッダー・Cookie・Content-Type・XSS 保護関連など）と、短時間のスパイダーによる URL 発見。**ヘッダーや Cookie 設定の変更による退行に気づく補助**として使う。
- **限界**: アクティブスキャン（SQL インジェクション・XSS 攻撃の送信）は行わない。認証が必要な画面の網羅や長時間クロールも対象外。Brakeman や依存関係スキャン（Dependabot / OSV など）の代替ではなく、**それらと併用する**前提。

詳細な設計の評価と運用方針は [dast-plan-review.md](dast-plan-review.md) を参照してください。

## 関連ファイル

| ファイル | 内容 |
|----------|------|
| [.github/workflows/dast.yml](../.github/workflows/dast.yml) | DAST ワークフロー定義 |
| [.github/actions/setup-rspec-env/](../.github/actions/setup-rspec-env/) | Ruby / Node / DB 準備（RSpec と共通） |
| [doc/dast-plan-review.md](dast-plan-review.md) | DAST 導入プランのレビューと役割・限界の整理 |
