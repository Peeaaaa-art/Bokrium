---
name: ship
description: 現在のissue worktreeの作業を出荷する。ローカルゲート(RuboCop/Brakeman/RSpec/型チェック)→PR作成→auto-merge→マージ後のissueコメント・worktree片付けまで。「PRを出して」「マージまでやって」のときに使う。
---

# 出荷フロー

前提: issue worktree上で作業しており、変更はコミット済み(未コミットがあれば先に整理してコミットする)。

## 1. ローカルゲート(全部通るまでPRを作らない)

```sh
bundle exec rubocop
bundle exec brakeman -q --no-pager   # CIのlintゲートと同一。permit!等はここで落ちる
npm run typecheck
docker compose run --rm web-test     # フルスイート(アセット・DB準備込み)
```

2回目以降のRSpecは `docker compose run --rm -e SKIP_TEST_PREPARE=1 web-test bundle exec rspec` で短縮できる。

ランタイムに触れる変更なら、PR前に組み込みの /verify(プロジェクトのverifyスキル)で実際に動かして確認する。

## 2. PR作成

```sh
git push -u origin issue/{N}-{name}
gh pr create --repo Peeaaaa-art/Bokrium --title "{日本語タイトル}" --body-file {body}
```

本文はリポジトリの慣例に従う:

- セクション: `## 概要` `## 対応` `## 影響範囲` `## Test plan`(実施済み項目をチェック済みで列挙)
- issueが完結するなら `Closes #{N}`、フェーズ分割なら `Part of #{N}`
- 末尾: `🤖 Generated with [Claude Code](https://claude.com/claude-code)`

## 3. マージ(squash)

```sh
gh pr merge {PR} --repo Peeaaaa-art/Bokrium --squash --auto --delete-branch
```

Monitorでマージ完了/CI失敗を監視する(`gh pr checks {PR}` で失敗ジョブ名を出す)。CIが落ちたら原因を直してpushし、監視を続ける。

## 4. マージ後の片付け

1. issueに完了コメント(やったこと+残タスク。フェーズ分割ならissueは閉じない)
2. worktreeの後始末:

```sh
docker compose down --remove-orphans
docker volume rm {dir}_bundle_cache {dir}_node_modules
cd ~/Workspace/Bokrium-worktrees/Bokrium
git worktree remove --force ~/Workspace/Bokrium-worktrees/{N}-{name}
git branch -D issue/{N}-{name}
```

共有Postgres内のworktree用DB(`{dir}_development` / `{dir}_test`)は害がないので基本残してよい。

3. ユーザーにPR URL・マージコミット・片付け結果を報告する。
