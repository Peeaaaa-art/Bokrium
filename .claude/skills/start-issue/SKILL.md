---
name: start-issue
description: GitHub issueの作業を開始する。issue番号を引数に取り(例 /start-issue 471)、issue確認→worktree作成→依存セットアップ→環境確認まで行う。ユーザーが「issue Nを始めて」「issue Nやろう」と言ったときにも使う。
---

# issue作業の開始

引数としてissue番号が渡される。以下を順に実行する。

## 1. issueを確認する

```sh
gh issue view {N} --repo Peeaaaa-art/Bokrium --comments
```

実装プランが書かれていなければ、着手前にプランを起案してissueにコメントし、ユーザーに方向性を確認する(CLAUDE.mdのIssue駆動開発)。

## 2. worktreeを作成する

ブランチ名は `issue/{N}-{内容を表す英語kebab-case}`、worktreeは `~/Workspace/Bokrium-worktrees/{N}-{内容}/`。

```sh
git fetch origin main
git worktree add ~/Workspace/Bokrium-worktrees/{N}-{name} -b issue/{N}-{name} origin/main
```

## 3. セットアップ

```sh
cd ~/Workspace/Bokrium-worktrees/{N}-{name}
cp ~/Workspace/Bokrium-worktrees/Bokrium/.env .env   # メインcheckoutからコピー
bundle install
npm install
```

共有Postgresコンテナの稼働確認(なければCLAUDE.mdの初回セットアップ手順で起動):

```sh
docker ps --filter name=bokrium-shared-db --format '{{.Names}} {{.Status}}'
```

## 4. 注意事項

- **npmパッケージを追加したら**、コンテナ内のnode_modulesボリュームは古いままなので、テスト前に `docker compose run --rm -e SKIP_TEST_PREPARE=1 web-test npm install` を実行する
- テストは `docker compose run --rm web-test`(ホストのPostgresは使わない)
- devサーバーやDB操作もdocker compose経由(AGENTS.md参照)

## 5. 報告

worktreeパス・ブランチ名・環境確認の結果をユーザーに報告し、実装に入る。
