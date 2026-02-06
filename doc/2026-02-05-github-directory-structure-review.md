# .github 構造レビュー（2026-02-05）

## 対象

- `.github/` 配下の設定・ワークフロー・カスタムアクションを読み、構造と運用の仕組みを整理

---

## 全体構造（テキスト図）

```text
.github
├─ actions/
│  ├─ setup-ruby-env/
│  └─ setup-rspec-env/
├─ instructions/
│  └─ tests.instructions.md
├─ workflows/
│  ├─ ci.yml
│  ├─ rspec.yml (reusable)
│  ├─ dependabot-auto-merge.yml
│  ├─ fly-deploy.yml
│  ├─ fly-sleep.yml
│  ├─ upload-vite-assets-to-r2.yml
│  ├─ scorecard.yml
│  ├─ semgrep.yml
│  ├─ osv-scanner.yml
│  ├─ trivy.yml
│  └─ hadolint.yml
├─ dependabot.yml
└─ copilot-instructions.md
```

- ファイル総数: 16
- `workflows/`: 11本
- `actions/`: 2本（composite action）
- `instructions/`: 1本

---

## 仕組み（ワークフロー連携・テキスト図）

```text
push / pull_request(main)
  -> CI
     -> RSpec reusable workflow

CI success (workflow_run)
  -> Dependabot auto-merge

push main
  -> Fly Deploy

frontend related change on main
  -> Upload Vite assets to Cloudflare R2

monthly schedule
  -> Scorecard / Semgrep / OSV-Scanner / Trivy / Hadolint

daily schedule
  -> Fly sleep/start
```

### CI 系

- `ci.yml` が品質ゲート本体（RuboCop/Brakeman/bundler-audit/deprecation + RSpec）
- `rspec.yml` を reusable workflow として呼び出し
- RSpec は `fast(4並列)` と `system(2並列)` を分離、最後に gate job で統合判定

### 依存更新系

- `dependabot.yml` は `bundler` / `npm` / `github-actions` を daily 更新
- `dependabot-auto-merge.yml` は patch 更新だけを対象に auto-merge
- `workflow_run: CI completed` を使って「CI成功後に最終マージ」の導線あり

### セキュリティ系

- Semgrep / Trivy / OSV / Hadolint / Scorecard を個別 workflow で実行
- 結果を SARIF で Security タブに連携
- `permissions` を絞る方針が全体に浸透

### デプロイ・運用系

- `fly-deploy.yml`: `main` push で本番デプロイ（`.md` 変更は除外）
- `fly-sleep.yml`: cron で夜間停止・朝起動（+ 手動実行）
- `upload-vite-assets-to-r2.yml`: フロント変更時のみ Vite ビルド & R2 反映

---

## 推しポイント（評価）

1. **CI設計が明確**: 再利用workflow + 並列 + gate で見通しと信頼性が高い
2. **多層セキュリティ**: 1ツール依存でなく、コード/依存/コンテナ/運用を分散カバー
3. **権限最小化**: workflow ごとの `permissions` 設計が丁寧
4. **再現性重視**: 多くの action がフルSHA pin されている
5. **開発者向け指示が具体的**: テスト作法ドキュメントの粒度が実務向き

---

## 改善ポイント（提案）

1. **checkout の重複削減**
   - `setup-ruby-env` が checkout を含む一方、呼び出し側 workflow でも checkout 済みの箇所がある
   - 実行時間と責務の観点で、どちらか一方に寄せると整理しやすい

2. **`fly-sleep` の手動実行挙動を明確化**
   - 現状 `workflow_dispatch` は停止側条件に含まれている
   - 手動時に `stop/start` を選べる input を追加すると誤操作を減らせる

3. **Dependabot patch 判定の堅牢化**
   - PR本文の grep 判定に依存する部分があるため、メタデータベースの判定に寄せると安全

4. **action pin 方針の統一**
   - 一部 composite action 内でタグ参照（例: `@v6`, `@v1`）が残る
   - ポリシーとして SHA 固定に統一すると監査しやすい

5. **`timeout-minutes` の追加**
   - 長時間ハング時の CI コスト抑制として、主要ジョブに明示設定を推奨

---

## 参照ファイル

- `.github/workflows/ci.yml`
- `.github/workflows/rspec.yml`
- `.github/workflows/dependabot-auto-merge.yml`
- `.github/workflows/fly-deploy.yml`
- `.github/workflows/fly-sleep.yml`
- `.github/workflows/upload-vite-assets-to-r2.yml`
- `.github/workflows/semgrep.yml`
- `.github/workflows/trivy.yml`
- `.github/workflows/osv-scanner.yml`
- `.github/workflows/hadolint.yml`
- `.github/workflows/scorecard.yml`
- `.github/actions/setup-ruby-env/action.yml`
- `.github/actions/setup-rspec-env/action.yml`
- `.github/dependabot.yml`
- `.github/copilot-instructions.md`
- `.github/instructions/tests.instructions.md`
