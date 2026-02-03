# Ruby 4.0 アップグレード前の破壊的変更チェック

**調査日**: 2025年2月  
**対象**: Bokrium（Rails 8.1.2 + Ruby 4.0.1。3.4.8 からアップグレード済）

## 結論

**Bokrium のアプリケーションコードに、Ruby 4.0 の破壊的変更で即座に動かなくなるパターンは見つかりませんでした。**

ただし **Rails 8.1 と Ruby 4.0 の公式対応状況** および **一部 Gem の Ruby 4.0 対応** は要確認です。本番適用前には必ず `bundle install` とテストスイートの実行で確認してください。

---

## 1. Ruby 4.0 の主な破壊的変更と Bokrium での該当有無

| 破壊的変更 | 内容 | Bokrium での該当 |
|-----------|------|------------------|
| **`*nil`** | `*nil` が `nil.to_a` を呼ばなくなった | **該当なし**（コード内に `*nil` / `**nil` なし） |
| **行頭の `&&` / `\|\|`** | 行頭の論理演算子が前の行の続きとみなされる | **該当なし**（該当パターンなし） |
| **`Kernel#open("|...")`** | 先頭 `\|` によるプロセス起動が削除 | **該当なし**（`File.open` のみ使用） |
| **`Binding#local_variables` 等** | 番号付き引数を含まない／扱わない | **該当なし**（該当 API 未使用） |
| **`Process::Status#&` / `#>>`** | 削除（3.3 で非推奨） | **該当なし** |
| **`ObjectSpace._id2ref`** | 非推奨 | **該当なし** |
| **Ractor の API 削除** | `Ractor.yield`, `#take`, `#close_incoming` 等 | **該当なし**（Ractor 未使用） |
| **CGI ライブラリ** | 完全な CGI が削除、escape 系のみ残る | **該当なし**（CGI 未使用） |
| **SortedSet** | stdlib から削除、`sorted_set` gem 要 | **該当なし**（SortedSet 未使用） |
| **Set#to_set / Enumerable#to_set** | 引数付き呼び出しが非推奨 | **該当なし**（引数付き `to_set` なし） |
| **Net::HTTP** | POST/PUT 時の Content-Type 自動付与が削除 | **影響なし**（GET のみ使用: OpenBD, Google Books, NDL） |

---

## 2. 要確認事項（アップグレード前に実施推奨）

### 2.1 Rails 8.1 と Ruby 4.0 の対応

- Rails 8.1 の公式要件は「Ruby >= 3.2.0」の記載が主で、Ruby 4.0 の明示的な言及は少ない。
- Ruby 4.0 は 2025年12月リリースのため、Rails 8.1.2 が 4.0 で動作するかは **実際に動かして確認** する必要がある。

**推奨**: ローカルで Ruby 4.0.1 を入れ、`bundle install` → `rails db:prepare` → `rspec`（または `bin/rails test`）を実行し、エラー・失敗がないか確認する。

### 2.2 Bundler 4

- Ruby 4.0 は Bundler 4 を同梱。
- 既存の `Gemfile.lock` は Bundler 3 で生成されている可能性が高い。Ruby 4.0 環境で `bundle install` を実行すると、Bundler 4 により lock が更新される。
- 問題が出た場合は [Upgrading to RubyGems/Bundler 4](https://blog.rubygems.org/2025/12/03/upgrade-to-rubygems-bundler-4.html) を参照。

### 2.3 依存 Gem の Ruby 4.0 対応

- 各 Gem が Ruby 4.0 をサポートしているかは、現時点で未対応のものがある可能性がある。
- **推奨**: Ruby 4.0.1 で `bundle install` を実行し、インストールエラーやバージョン制約エラーが出ないか確認。エラーが出た Gem は、Ruby 4.0 対応版があるか公式・GitHub で確認する。

---

## 3. 実施したコード検索の概要

- **検索対象**: `*.rb`（app, config, lib, spec, db 等）
- **検索内容**:
  - `*nil` / `**nil` → なし
  - `open("|"` や `open('|'` → なし（`File.open` のみ）
  - 行頭の `&&` / `||` / `and` / `or` → なし
  - `Binding#local_variables` / `local_variable_get` / `local_variable_set` → なし
  - `Process::Status` および `#&` / `#>>` の使用 → なし
  - `ObjectSpace._id2ref` → なし
  - Ractor の削除 API → なし
  - `CGI` → なし
  - `SortedSet` / `require "set"` → なし
  - `to_set(...)`（引数付き）→ なし
- **Net::HTTP**: `app/services/book_apis/` で GET のみ使用のため、Ruby 4.0 の Content-Type 変更の影響なし。

---

## 4. アップグレード手順の提案

1. **Dockerfile は 4.0.1-slim-bookworm に変更済み** の場合、そのまま利用可。
2. **.ruby-version** を `4.0.1` に変更。
3. **Gemfile** の `ruby "~> 3.4.8"` を `ruby "~> 4.0.1"` に変更。
4. ローカルに Ruby 4.0.1 をインストールし、`bundle install` を実行。
5. `rails db:prepare`（必要に応じて `db:migrate`）で DB を準備。
6. テストスイートを実行（例: `bundle exec rspec`）。
7. 問題がなければ Docker イメージをビルドし、Trivy 等で CVE 解消を確認。

上記でエラーやテスト失敗が出た場合は、その時点で Rails / 個別 Gem の Ruby 4.0 対応状況をあらためて確認することを推奨します。
