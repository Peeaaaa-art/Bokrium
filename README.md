# Bokrium

🌐 **サービスURL:** [https://bokrium.com](https://bokrium.com)

[![Image from Gyazo](https://i.gyazo.com/339ded291d706d0b69c11956dbf3732c.png)](https://gyazo.com/339ded291d706d0b69c11956dbf3732c)
 
## 目次

- [📖 Bokriumとは](#-bokriumとは)
- [🎯 こんな方におすすめ](#-こんな方におすすめ)
- [🛠 開発の背景](#-開発の背景)
- [✨ アプリ機能紹介](#-アプリ機能紹介)
  - [📧 ユーザー登録](#-ユーザー登録)
  - [🤳📚 書籍登録](#-書籍登録)
  - [📚👀 本棚](#-本棚)
  - [🔍 快適な検索と閲覧体験](#-快適な検索と閲覧体験)
  - [📝 メモ機能](#-メモ機能)
  - [💌 ランダム通知機能](#-ランダム通知機能)
  - [🎁 支援機能](#-支援機能)
- [🛠 使用技術](#-使用技術)
- [📡 インフラ図](#-インフラ図)
- [🗂 ER図・テーブル設計](#-er図テーブル設計)
 
 
## 📖 Bokriumとは

読書を「知識として蓄積し、身体化する」ことを目指す読書管理アプリです。 
書籍の登録からメモ・画像・タグの追加、公開設定、ランダム通知などを備え、読書の記録を繰り返し見直せる設計。
得た知識を記憶にとどめ、日々の選択や行動に結びつけるための、実践的なツールです。
  
## 🎯 こんな方におすすめ

- 本は好きだけど、読んだ内容を活かせていない  
- 同じ本をうっかり重複して買ってしまう  
- 自分の蔵書を整理して把握したい  
- 読書メモや気づきをあとで見返したい
- スマホに本のスクリーンショット画像が溜まってしまう

## 🛠 開発の背景

書籍を管理するアプリをいくつか試してみましたが、自分が本当に使いたいと思えるものには出会えませんでした。
ならば、自分で作ってしまおう——。そんなシンプルな衝動が、Bokriumの出発点です。

かつて書店員として本に囲まれながら働き、日常的に読書を続けるなかで、こう感じるようになりました。

**読書とは、知識をただ増やす行為ではなく、それを必要なときに取り出し、現実の中で活かしてこそ意味があるのだと。**

Bokriumは、そのための場です。知識を、思い出しやすく、取り出しやすい形で格納する。
単なる記録ではなく、再び触れたくなるような形で残す。
メモやタグ、画像、そして偶然性のある再会——。
本と向き合った時間を、静かに、でも確かに、日常へとつなげてくれる場所を目指して、このアプリを作りました。

## ✨ アプリ機能紹介

<h3 align="center">📧 ユーザー登録</h3>

| メール認証とLINEログインの両対応 |
|-------------------------|
| <p align="center">[<img src="https://i.gyazo.com/b3a227e6b54caa8893d1708fa3fd1bfc.png" alt="ログイン画面" width="100%">](https://i.gyazo.com/b3a227e6b54caa8893d1708fa3fd1bfc)</p> |
| アカウント登録にはDeviseによるメール認証を採用しており、安全性を確保しつつ、確認メールのリンクをクリックするだけで、そのままログイン状態になります。登録後のパスワード再設定も、メール送信によるリンク経由で安心して実施可能です。また、LINEログインにも対応しており、メールアドレスやパスワードの入力なしで、ワンタップで簡単に登録・ログインができます。 |

<br><h3 align="center">🤳📚 書籍登録</h3>

| バーコードスキャン | キーワード検索 |
|------------------|---------------------|
| <p align="center"><a href="https://gyazo.com/88615713f29c4da2bd917487a84d9f53"><img src="https://i.gyazo.com/88615713f29c4da2bd917487a84d9f53.gif" width="250" alt="バーコードスキャンGIF"></a></p> | <p align="center"><img src="https://github.com/user-attachments/assets/56efe725-fb4a-49a2-91d4-3e35a34cc117" width="250" alt="キーワード検索"></p> |
| <p align="center">ZXing[^1]を用いたクライアントサイドのバーコードスキャン機能。取得したISBNを非同期で送信し、複数のAPIから書誌情報を統合取得します。</p> | <p align="center">タイトル・著者をもとに、楽天・Google Booksを切り替えて検索可能。ISBNでの検索も可能。</p> |

<details>
<summary><strong>🦓📚 ISBN登録処理の全体フロー</strong></summary>

<pre>
📱 スマホでバーコードをスキャン（🦓ZXing）   ⌨️ ユーザーが手動でISBNを入力
             │                                      │
             ▼                                      ▼
   ISBNを直接取得（正規フォーマット）       ✅ IsbnCheckサービス群でバリデーション処理
                                        ├─ ハイフン・スペース除去や "X" の正規化  
                                        ├─ ISBN-10 → ISBN-13 自動変換  
                                        ├─ チェックデジットによる妥当性検証  
                                        └─ I18n 対応の適切なメッセージ表示  

             └─────── 📘 正常なISBNが取得されたら ───────┘
                                 ▼
          🌐 ISBNをもとに書誌情報を取得（以下の順で呼び出し）  
           ├─ ① openBD  
           ├─ ② Rakuten Books API  
           ├─ ③ Google Books API  
           └─ ④ 国立国会図書館サーチAPI（NDL API）  
   
  ▼───  🧩 各APIから取得した情報は、不足項目を補完するかたちで統合  -──▼
   ▼──     → タイトル・著者・出版社・書影 の4項目が揃った時点で完了 ──▼ 
                                 ▼  
                 🖼 Bokrium に書籍プレビューを表示  
                                 ▼  
                 ✅ 「本棚に追加」ボタンをクリック  
                                 │  
         ┌───────────────────────────────────────────────┐  
         │ すでに同じ書籍が登録されている場合は、重複登録を防止し │  
         │ ⚠️ フラッシュメッセージでユーザーに通知されます。     │  
         └───────────────────────────────────────────────┘  
                                 ▼  
                  📚 書籍情報を本棚に登録・表示！
</pre>
</details>


<br><h3 align="center">📚👀 本棚</h3>

| ビューと表示冊数を選べる本棚 |
|-------------------------|
| <p align="center">[<img src="https://i.gyazo.com/fb85667d739a8c62f3abab2a9703d247.png" alt="本棚一覧画像" width="100%">](https://gyazo.com/fb85667d739a8c62f3abab2a9703d247)</p> |
| <p align="center">[<img src="https://i.gyazo.com/7a994cfc549125f3977c8f87e03daae5.png" alt="棚設定UI" width="100%">](https://gyazo.com/7a994cfc549125f3977c8f87e03daae5)</p> |
| <p align="center">[<img src="https://i.gyazo.com/262949cb147fe5434171f211b7c5864d.gif" alt="本棚レイアウト切り替えGIF" width="100%">](https://gyazo.com/262949cb147fe5434171f211b7c5864d)</p> |
| ユーザーは5種類の本棚レイアウト（棚・カード・背表紙・リスト・表形式）と表示冊数を自由に切り替えることができます。選択したレイアウトと冊数はセッションに保存され、次回以降も自分の好みに合わせた状態が維持されます。 |


<details>
<summary><strong>📦 本棚表示機能における責務分離構成</strong></summary>
<pre>
app/
├── controllers/      # 表示制御・状態更新を担うコントローラ群
├── queries/          # DBクエリロジックを集約し、N+1を防止
├── presenters/       # 表示用ロジックや初期値の定義を分離
├── views/            # Turbo・Pagy・Stimulusを組み合わせた本棚UIの土台
│   └── books/        
├── components/       # ViewComponent による本棚の各表示レイアウト・UI部品
│   └── books/        
</pre>

表示処理の責務を明確に分離しており、Controllerは状態処理、QueryはDBアクセス、Presenterは表示ロジック、ViewはHotwire[^2]によるUX、Componentは再利用可能なUI部品という役割に分けています。
構造を保ちながらも、表示の拡張や保守がしやすい柔軟な設計を意識しています。

</details>
 
<br><h3 align="center">🔍 快適な検索と閲覧体験</h3>

| オートコンプリート | 無限スクロール |
|------------------|---------------------|
| <p align="center"><a href="https://gyazo.com/087b7bf154e1baab02d44c3a45e787be"><img src="https://i.gyazo.com/087b7bf154e1baab02d44c3a45e787be.gif" width="250" alt="オートコンプリートGIF"></a></p> | <p align="center"><img src="https://github.com/user-attachments/assets/c08fc27c-0d02-4553-b4db-b8fe40b75b3e" width="250" alt="無限スクロール"></p> |
| <p align="center">タイトルや著者名の一部を入力すると候補が表示。タイポや曖昧な記憶でも探しやすく、検索体験をスムーズに。</p> | <p align="center">Turbo + Pagy を用いた軽量な実装。表示冊数に応じて読み込み、美しく快適な本棚体験を。</p> |

 
<br><h3 align="center">📝 メモ機能</h3>

| 📝 本ごとにメモ・画像・タグをまとめて管理 |
|-------------------------|
| <p align="center">[<img src="https://i.gyazo.com/d1fe020ed89a02f13b27dea417abe1ab.gif" alt="本ごとのまとめ表示" width="100%">](https://gyazo.com/d1fe020ed89a02f13b27dea417abe1ab)</p> |
| **読書メモ**には、**Markdown対応のTipTapエディタ**を採用。見たまま編集できる直感的なUI。さらに、タグ付けや書籍情報の編集、「読書中・読みたい・読了」といったステータスの設定にも対応。
**通常表示**では、左上に拡大・縮小ボタン、右上に「非公開・リンク限定・公開」から選べる公開設定メニューが表示されます。
**モーダル表示**では、メモの文字数や作成日・更新日も確認できます。保存ボタンの自動制御や改行仕様にも細かく対応し、ストレスのない編集体験を提供しています。 |

 
<br><h3 align="center">📝 ランダム通知機能</h3>

| 💌 ランダムメモをLINE・メールで通知 |
|-------------------------|
| <p align="center">[<img src="https://i.gyazo.com/824716aad7a7d4a02f4e184eb7c3ee63.png" alt="メモ通知UIイメージ" width="100%">](https://gyazo.com/824716aad7a7d4a02f4e184eb7c3ee63)</p> |
| Bokrium独自の機能として、登録済みの読書メモからランダムに1件を選び、LINEまたはメールでお届けします。「あの本、こんなこと書いてたな」と自然に思い出すことで、読書体験を日常に再接続し、知識の身体化を促します。ただ書き留めるだけで終わらせず、繰り返し触れることで定着させる仕組みを作りました。|


<br><h3 align="center">🎁 支援機能</h3>

| Stripeによる寄付・サポートに対応 |
|-------------------------|
| <p align="center">[<img src="https://i.gyazo.com/c0e217d7dd08a575e7f4587c4f2e17a6.png" alt="支援機能" width="100%">](https://i.gyazo.com/c0e217d7dd08a575e7f4587c4f2e17a6.png)</p> |
| Bokriumの理念に共感いただけた方へ、**単発の寄付**や**月額サポート**というかたちで応援していただける仕組みを導入しています。<br>Stripe Checkout による安全な決済に対応し、支援の想いをかたちにできる場を設けています。 |

<br>
 
## 🛠 使用技術

| カテゴリ       | 技術構成                                                                                                      |
|----------------|---------------------------------------------------------------------------------------------------------------|
| フロントエンド | Hotwire（Stimulus・Turbo） / React（TipTap専用） / Vite / TypeScript                                                |
| バックエンド   | Ruby 3.4.3 / Ruby on Rails 8.0.2                                                                              |
| データベース   | PostgreSQL（Neon） / pg_search                                                                               |
| インフラ       | Fly.io / Cloudflare（DNS管理・CDN、Viteビルドアセットの配信にCloudflare R2を使用）         |
| 環境構築       | Docker                                                              |
| CI/CD | GitHub ActionsでPR時にRuboCop・Brakeman・RSpecを実行。mainマージ時に、Fly.ioへ自動デプロイ＋ViteアセットをR2へアップロード（CDN配信）。 |
| 開発支援       | Bullet（N+1検出） / rack-mini-profiler |
| 認証           | Devise（メールログイン）/ OmniAuth（LINEログイン対応）                |
| 画像処理       | Active Storage / libvips / Cloudflare R2                                                            |
| メモエディタ   | TipTap（Reactベース WYSIWYGエディタ）                                                                        |
| 通知機能       | LINE Messaging API、ActionMailer + cron-job.org（定期メモ通知）                                   |
| 支援機能       | Stripe（寄付・マンスリーサポート）                                                                           |
| 検索・UX       | 無限スクロール（Turbo + Pagy）、オートコンプリート（書籍タイトル・著者）、フィルター・ソート機能          |
| その他         | Bootstrap / ViewComponent / Pagy                                 |

<br>

## 📡 インフラ図
[![インフラ図](https://i.gyazo.com/765ddbb70bc87fe1662edf6ef1768a73.png)](https://gyazo.com/765ddbb70bc87fe1662edf6ef1768a73)

<details>
<summary><strong>📡 インフラ構成の詳細</strong></summary>
 
>#### アプリケーションには Ruby on Rails を採用

Webアプリに必要な機能が揃ったフルスタックフレームワークであり、個人開発でも本番品質の構築がしやすいと感じたためです。
「設定より規約」や「DRY原則」に基づく Rails Way の設計思想、フロントとバックエンドを統合的に扱える構造により、一貫性とスピードのある開発が可能でした。

>#### インフラには Fly.io を採用

東京リージョンにDockerごとデプロイでき、同価格帯の中でもマシン性能が高く、スケーリングも柔軟だったためです。
コストを抑えつつ本番運用にも無理なく対応できる点が決め手となりました。

>#### データベースは Neon、ストレージは Cloudflare R2 を採用

Fly.io付属のDBはマネージド化するとコストが高く、Neonは半額以下で済み、接続の安定性やFly.io公式の推奨も後押しとなりました。
ストレージには当初S3を使用していましたが、転送量課金のないR2へ移行。S3互換APIによりスムーズな切り替えができ、CDNとの統合も容易でした。

>#### パフォーマンスと運用面の工夫

画像アップロードは署名付きURLでRailsと分離し、セキュアかつ低負荷な構成に。静的アセットや画像はCloudflare CDN経由で高速配信しています。
定期処理はcron-job.orgを用いた外部スケジューリングで対応し、CI/CDはGitHub Actionsで自動化。開発から本番反映までの流れを効率化しています。
</details>

<br>

## 🗂 ER図・テーブル設計
[![ER図・テーブル設計](https://i.gyazo.com/773f2b9900b1460aecfea5a1fee2d8b4.png)](https://gyazo.com/773f2b9900b1460aecfea5a1fee2d8b4)

<details>
<summary><strong>🗂 テーブル設計の詳細</strong></summary>
 
>#### Bokriumは、読書メモと本棚管理を中心とした構成です。

`books`, `users`, `memos` を軸に、メモはユーザーと書籍に属する中間モデルとして設計。<br>
公開範囲は `visibility`（enum）で制御し、いいね機能は `like_memos` に分離。<br>
タグは `user_tags` によってユーザーごとに管理し、`book_tag_assignments` により書籍と多対多の関係を構築。<br>
画像は `images` テーブルで管理しており、1冊の本に対して複数枚のアップロードが可能です。各画像は Active Storage を通じて Cloudflare R2 に保存され、署名付きURLによる直接アップロードとCDN配信に対応。<br>
通知機能は、`line_users` でLINE連携、`users.email_notification_enabled` でメール配信を制御。<br>
支援機能としては、Stripe による単発寄付（`donations`）と継続支援（`monthly_supports`）を実装。

全体として、拡張性と役割の分離を重視し、成長や変更に強い構成を目指しました。


>#### なぜ PostgreSQL なのか

Bokriumでは、読書メモや書籍情報を対象とした日本語の全文検索を重視しており、pg_search[^3] を活用できる PostgreSQLの全文検索機能は必須でした。  
また、Railsとの高い親和性と、安定した同時接続処理が求められる点でも、SQLiteやMySQLではなく PostgreSQL が最適と判断しました。  
本番環境では、スケーラブルかつコストパフォーマンスに優れたマネージドサービスである Neon を利用しています。
</details>

<br>

[^1]: [ZXing（Zebra Crossing）](https://www.npmjs.com/package/@zxing/library) は、Java製のオープンソース1D/2Dバーコード処理ライブラリで、Web向けには `@zxing/library` パッケージが提供されています。**認識精度が高い**ことから、最終的にBokriumで採用しました。    

[^2]: [Hotwire](https://github.com/hotwired) は “HTML over the wire” を略した名前で、Turbo（リンク遷移・部分更新）と Stimulus（UI制御）を組み合わせることで、サーバー側でHTMLを生成してクライアントへ送信する設計思想のことです。BokriumではこれをTurbo（部分更新）+ Stimulus（UI操作）で実現し、JavaScript中心のSPAに頼らず、  RailsのMVC構造を保ちながらもスムーズで動的なUXを提供しています。

[^3]: [pg_search](https://github.com/Casecommons/pg_search) は、PostgreSQLの全文検索機能を活用できる Rails用の検索ライブラリです。`tsearch` や `trigram` を通じて、日本語検索にもある程度対応できます。
