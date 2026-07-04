# CLAUDE.md

Bokrium(bokrium.com)の開発方針。

## Issue駆動開発

実装前に対応するGitHub issueを確認する。実装プランが書かれていなければ、着手前にissueへ書く。作業はissueに紐づけて進める。

## ブランチ命名

`issue/{issue番号}-{実装内容を表す英語(kebab-case)}`

例: `issue/33-export-books-to-csv`

## Worktree

issueごとに作業用のworktreeを作る。メインの作業ディレクトリ(`~/Workspace/Bokrium`)の状態を汚さないため。

- 配置場所: `~/Workspace/Bokrium-worktrees/{issue番号}-{実装内容を表す英語}/`
- ディレクトリ名はブランチ名から `issue/` を除いたもの
- ベースブランチは常に最新の `origin/main`

```sh
git fetch origin main
git worktree add ~/Workspace/Bokrium-worktrees/{issue番号}-{実装内容を表す英語} \
  -b issue/{issue番号}-{実装内容を表す英語} origin/main
```

作業が終わったら、マージ後に `git worktree remove` で片付ける。
