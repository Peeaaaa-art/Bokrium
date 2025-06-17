# Neon DB 移行メモ

## なぜ Fly.io の DB をやめたか

- Fly.io の Postgres は **unmanaged 扱い**で、
  - 自動バックアップやフェイルオーバーがない
  - 複数アプリでの共有も難しく、運用に不安
  - 自動スリープ機能がなく、**コストがかさむ可能性**があった
- Bokrium は **Stripe 決済対応**など信頼性が重要なので、
  管理された高信頼な環境に移行したかった

---

## Neon の利点

- **Freeプランでも高性能**
  - ストレージ：0.5GB
  - 計算時間：190 compute hours/月
  - CU（Compute Units）自動スケーリング（最大2CU）

- **Launchプラン（$19/月）で十分なリソースとサポート**
  - ストレージ：10GB
  - 計算時間：300 compute hours/月
  - 最大4CUまでスケール可能

- その他の特長
  - AutoSleep 対応：未使用時は休止してコスト節約
  - PgBouncer 相当の接続制御が自動で行われる
  - Read Replica や高可用性が無料で利用可能

---

## 実装したこと

### Neon の接続設定

- `DATABASE_URL` を Neon のものに変更
- `production.rb` や `config/database.yml` に反映

### スリープ防止対策

- `DbPingWorker` を 5分おきに実行する Sidekiq Worker を作成
- `SELECT 1` を投げて、Neon の AutoSleep を防止
- `config/sidekiq.yml` で cron スケジュールを定義

```yaml
:schedule:
  db_ping:
    cron: "*/5 * * * *"
    class: "DbPingWorker"
    queue: default
```

## Sidekiq 設定

- `sidekiq-cron`, `sidekiq-unique-jobs` を導入
- `.env` や `REDIS_URL` を統一して、Worker で共通利用

---

## 今後の対応

- ユーザー数が増えたら **Neon の Launch プラン（$19/月）** へ移行検討
- DB バックアップポリシーや監視（NewRelic, Logtailなど）も段階的に導入
- メトリクスやスロークエリログなど、より深い監視は今後の課題

---

## 備考

- `DownloadCoverImageWorker` など画像処理系は Sidekiq 経由で Redis と連携
- スリープ対策と競合しないよう、Worker の Queue 設定は明確に定義