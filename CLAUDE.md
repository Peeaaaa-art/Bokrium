# CLAUDE.md

Bokrium(bokrium.com)の開発方針。

## Issue駆動開発

実装前に対応するGitHub issueを確認する。実装プランが書かれていなければ、着手前にissueへ書く。作業はissueに紐づけて進める。

## ブランチ命名

`issue/{issue番号}-{実装内容を表す英語(kebab-case)}`

例: `issue/33-export-books-to-csv`

## Worktree

issueごとに作業用のworktreeを作る。メインのcheckout(`~/Workspace/Bokrium-worktrees/Bokrium`)の状態を汚さないため。

- 配置場所: `~/Workspace/Bokrium-worktrees/{issue番号}-{実装内容を表す英語}/`
- ディレクトリ名はブランチ名から `issue/` を除いたもの
- ベースブランチは常に最新の `origin/main`

```sh
git fetch origin main
git worktree add ~/Workspace/Bokrium-worktrees/{issue番号}-{実装内容を表す英語} \
  -b issue/{issue番号}-{実装内容を表す英語} origin/main
```

作業が終わったら、マージ後に `git worktree remove` で片付ける。

新しいworktreeでは、gitに含まれない以下のセットアップが別途必要:

```sh
cp ~/Workspace/Bokrium-worktrees/Bokrium/.env .env
bundle install
npm install
```

**npmパッケージを追加・更新したら**、Dockerボリューム内のnode_modulesは古いままなので、テスト前にコンテナ内でもインストールする:

```sh
docker compose run --rm -e SKIP_TEST_PREPARE=1 web-test npm install
```

## 共有Postgresコンテナ

worktreeごとに `db` サービスを起動すると、host側のport 5432を奪い合って複数worktreeを同時に動かせない。そのため、Postgresはマシンに1つだけ常駐させ、全worktreeで共有する(DB名はworktreeごとに分離されるためデータが混ざることはない)。

初回のみ、専用の共有ネットワークとコンテナをマシンに1つ起動しておく:

```sh
docker network create bokrium-shared
docker volume create bokrium-shared-db-data
docker run -d --name bokrium-shared-db \
  --network bokrium-shared \
  -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres \
  -v bokrium-shared-db-data:/var/lib/postgresql/data \
  postgres:16
```

各worktreeの `docker-compose.yml` は `networks.default` をこの `bokrium-shared` ネットワーク(external)に参加させており、`web`/`web-test` サービスはコンテナ名 `bokrium-shared-db` で接続する。DB名は `${COMPOSE_PROJECT_NAME}` (worktreeのディレクトリ名)からworktreeごとに自動的に一意な名前が組み立てられるので、手動設定は不要。

host側のport 5432は公開しない(Homebrew版postgresなど、host上の既存プロセスと衝突しないようにするため)。

## テスト実行(Docker)

ローカルのHomebrew版PostgreSQLは `pg_trgm` 拡張のバージョン不整合で動かないことがあるため、開発・テストは `docker-compose.yml` の `web-test` サービスを使う。

```sh
docker compose run --rm web-test
```

内部でアセットビルド・`db:prepare`・`bundle exec rspec` が自動実行される(`bin/docker-test-entrypoint` 参照)。個別のspecだけ実行したい場合:

```sh
docker compose run --rm web-test bundle exec rspec spec/requests/exports_spec.rb
```

## PR前のローカルゲート

CIで落ちる前にローカルで全部通す(Brakemanはlintゲートとして必須。`permit!`などはここで落ちる):

```sh
bundle exec rubocop
bundle exec brakeman -q --no-pager
npm run typecheck
docker compose run --rm web-test
```

PRの本文は `## 概要` `## 対応` `## 影響範囲` `## Test plan` 形式、マージはsquash。

## フロントエンドの規約

- アイコンは `bi_icon` ヘルパー経由で `app/assets/icons/{name}.svg` を読む。未追加のアイコンは公式Bootstrap Iconsから取得する:
  `curl -sf https://raw.githubusercontent.com/twbs/icons/main/icons/{name}.svg -o app/assets/icons/{name}.svg`
- ページ専用のVite entrypoint(`app/frontend/entrypoints/*.tsx`)を追加するときは、`turbo:load` リスナーに加えて**モジュール評価時の即時マウント**も行う。Turbo遷移で初めて読み込まれた場合、`turbo:load` は発火済みのため(実例: `handwritten_note.tsx`)
- 重いライブラリはページ専用entrypointに分離し、既存ページのバンドルに影響させない(`vite build` 後にマニフェストで確認)

## Claude Code

- セッションは**worktreeディレクトリ内で起動する**。`.claude/settings.json`(権限allowlist・RuboCopフック)とプロジェクトスキルはそこから読み込まれる
- スキル: `/start-issue {N}`(issue着手の定型セットアップ)、`/ship`(ローカルゲート→PR→auto-merge→片付け)、`/verify`(実アプリでの動作確認手順)
