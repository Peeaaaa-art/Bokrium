#!/usr/bin/env bash
# PostToolUse hook: Edit/Writeされた *.rb にRuboCopをかけ、違反をClaudeにフィードバックする。
# stdinにはtool呼び出しのJSONが渡される({"tool_input":{"file_path":...}} など)。
set -u

file=$(jq -r '.tool_input.file_path // empty')
[[ "$file" == *.rb && -f "$file" ]] || exit 0

# worktree運用のため、対象ファイルが属するリポジトリのルートで実行する
root=$(cd "$(dirname "$file")" && git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
[[ -f Gemfile ]] || exit 0

# bundle未セットアップのworktreeでは静かにスキップ
bundle exec rubocop --version >/dev/null 2>&1 || exit 0

output=$(bundle exec rubocop --force-exclusion --format simple "$file" 2>&1)
if [[ $? -ne 0 ]]; then
  echo "$output" >&2
  exit 2
fi
exit 0
