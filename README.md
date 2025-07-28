# Bokrium

🌐 **サービスURL:** [https://bokrium.com](https://bokrium.com)

[![Image from Gyazo](https://i.gyazo.com/339ded291d706d0b69c11956dbf3732c.png)](https://gyazo.com/339ded291d706d0b69c11956dbf3732c)

# 元書店員が開発した読書管理アプリ

本を「読むだけ」で終わらせず、  
知識を整理し、実践につなげるための読書管理アプリです。

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

[📧 ユーザー登録](#-ユーザー登録)

[🤳📚 書籍登録（バーコード・キーワード）](#-書籍登録)

[📚👀 本棚レイアウト切り替え](#-本棚)

[🔍 快適な検索と閲覧体験](#-快適な検索と閲覧体験)

[📝 読書メモ・画像・タグの記録](#-メモ機能)

[💌 ランダム通知で知識を再発見](#-ランダム通知機能)

<h3 align="center">📧 ユーザー登録</h3>

|  メールログイン | LINEログイン |
|:--:|:--:|
| [<img src="https://i.gyazo.com/6d197a7c7065f88081a28347c04106e2.png" alt="メールログイン画面" width="590">](https://gyazo.com/6d197a7c7065f88081a28347c04106e2) | [<img src="https://i.gyazo.com/e35992b842ae24c8149e96275682ff9b.png" alt="LINEログイン画面" width="600">](https://gyazo.com/e35992b842ae24c8149e96275682ff9b) |

アカウント登録にはDeviseによるメール認証を採用しており、安全性を確保しつつ、確認メールのリンクをクリックするだけで、そのままログイン状態になります。登録後のパスワード再設定も、メール送信によるリンク経由で安心して実施可能です。また、LINEログインにも対応しており、メールアドレスやパスワードの入力なしで、ワンタップで簡単に登録・ログインができます。

<br><h3 align="center">🤳📚 書籍登録</h3>

| バーコードスキャン | キーワード検索 |
|------------------|---------------------|
| <p align="center"><a href="https://gyazo.com/88615713f29c4da2bd917487a84d9f53"><img src="https://i.gyazo.com/88615713f29c4da2bd917487a84d9f53.gif" width="250" alt="バーコードスキャンGIF"></a></p> | <p align="center"><img src="https://github.com/user-attachments/assets/56efe725-fb4a-49a2-91d4-3e35a34cc117" width="250" alt="キーワード検索"></p> |
| <p align="center">ZXingを用いたクライアントサイドのバーコードスキャン機能。取得したISBNを非同期で送信し、複数のAPIから書誌情報を統合取得します。</p> | <p align="center">タイトル・著者をもとに、楽天・Google Booksを切り替えて検索可能。ISBNでの検索も可能。</p> |

### 🦓📚 ISBN登録処理の全体フロー
<pre>
🛤 ISBNの取得には2つのルートがあります：

① 📱 スマホでバーコードをスキャン（🦓 ZXing使用）
   └ 書籍から直接ISBNを取得（正規なフォーマット）

② ⌨️ ユーザーが手動でISBNを入力
   └─ 以下のようなバリデーション処理を備えた
      専用の IsbnCheck サービス群 を導入：

       ✅ ハイフン・スペース除去や "X" の正規化  
       ✅ ISBN-10 → ISBN-13 自動変換  
       ✅ チェックデジットによる妥当性検証  
       ✅ エラー時は I18n 対応の適切なメッセージ表示  

      ※内部では以下の2クラスを利用：
        - IsbnCheck::IsbnService（正規化・変換・検証）
        - IsbnCheck::ValidateIsbnService（統合バリデーション）

------------------------------------------
ISBNの取得が完了したら、後続処理は共通です：

🌐 ISBNをもとに書誌情報を取得  
   └ 以下のAPIをこの順で呼び出します：  
        ① openBD  
        ② Rakuten Books API  
        ③ Google Books API  
        ④ 国立国会図書館サーチAPI（NDL API）  

   各APIから取得した情報は、  
   不足項目を補完するかたちで統合されます。  
   タイトル・著者・出版社・書影の4項目が揃った時点で完了します。  
               ↓  
🖼 Bokrium に書籍プレビューを表示し、ユーザーが確認  
               ↓  
✅ 「本棚に追加」ボタンをクリック
   └ ※ すでに同じISBNの書籍が登録されている場合は、  
        重複登録を防ぐため処理がスキップされ、  
        ⚠️ フラッシュメッセージでユーザーに通知されます。
               ↓  
📚 書籍情報を本棚に登録・表示！
</pre>



<br><h3 align="center">📚👀 本棚</h3>

| ビューと表示冊数を選べる本棚 |
|-------------------------|
| <p align="center">[<img src="https://i.gyazo.com/fb85667d739a8c62f3abab2a9703d247.png" alt="本棚一覧画像" width="100%">](https://gyazo.com/fb85667d739a8c62f3abab2a9703d247)</p> |
| <p align="center">[<img src="https://i.gyazo.com/7a994cfc549125f3977c8f87e03daae5.png" alt="棚設定UI" width="100%">](https://gyazo.com/7a994cfc549125f3977c8f87e03daae5)</p> |
| <p align="center">[<img src="https://i.gyazo.com/262949cb147fe5434171f211b7c5864d.gif" alt="本棚レイアウト切り替えGIF" width="100%">](https://gyazo.com/262949cb147fe5434171f211b7c5864d)</p> |
| 書籍ごとに読書メモ・タグ・画像をまとめて保存。5つの本棚レイアウトを自由に切り替えて、見やすく振り返りやすい読書体験を提供します。 |

<br><h3 align="center">🔍 快適な検索と閲覧体験</h3>

| オートコンプリート | 無限スクロール |
|------------------|---------------------|
| <p align="center"><a href="https://gyazo.com/087b7bf154e1baab02d44c3a45e787be"><img src="https://i.gyazo.com/087b7bf154e1baab02d44c3a45e787be.gif" width="250" alt="オートコンプリートGIF"></a></p> | <p align="center"><img src="https://github.com/user-attachments/assets/c08fc27c-0d02-4553-b4db-b8fe40b75b3e" width="250" alt="無限スクロール"></p> |
| <p align="center">タイトルや著者名の一部を入力すると候補が表示。タイポや曖昧な記憶でも探しやすく、検索体験をスムーズに。</p> | <p align="center">Turbo + Stimulus を用いた軽量な実装。表示冊数に応じて読み込み、美しく快適な本棚体験を。</p> |

<br><h3 align="center">📝 メモ機能</h3>

| 📝 本ごとにメモ・画像・タグをまとめて管理 |
|-------------------------|
| <p align="center">[<img src="https://i.gyazo.com/d1fe020ed89a02f13b27dea417abe1ab.gif" alt="本ごとのまとめ表示" width="100%">](https://gyazo.com/d1fe020ed89a02f13b27dea417abe1ab)</p> |
| 読書メモには、Markdown対応のTipTapエディタを採用。見たまま編集できる直感的なUIで、プレーンテキストもHTMLも扱えます。<br>画像はS3に保存され、スムーズに管理可能です。<br>さらに、タグ付けや書籍情報の編集、読書中・読みたい・読了といったステータスの設定にも対応。<br><br>通常表示では、左上に拡大・縮小ボタン、右上に「非公開・リンク限定・公開」から選べる公開設定メニューが表示されます。モーダル表示では、メモの文字数や作成日・更新日も確認できます。 |

<br><h3 align="center">📝 ランダム通知機能</h3>

| 💌 ランダムメモをLINE・メールで通知 |
|-------------------------|
| <p align="center">[<img src="https://i.gyazo.com/824716aad7a7d4a02f4e184eb7c3ee63.png" alt="メモ通知UIイメージ" width="100%">](https://gyazo.com/824716aad7a7d4a02f4e184eb7c3ee63)</p> |
| 登録済みの読書メモの中から、毎朝ランダムに1件を選んでLINEまたはメールでお届けします。<br>「あの本、こんなこと書いてたな」と自然に思い出せる、ちょっと嬉しい仕組みです。 |



## 🛠 使用技術

| カテゴリ       | 技術構成                                                                                                      |
|----------------|---------------------------------------------------------------------------------------------------------------|
| フロントエンド | Hotwire(Stimulus・Turbo) / React（TipTap専用） / Vite / TypeScript                                                |
| バックエンド   | Ruby 3.4.3 / Ruby on Rails 8.0.2                                                                              |
| データベース   | PostgreSQL（Neon） / pg_search                                                                               |
| インフラ       | Fly.io / Cloudflare（DNS管理・CDN、Viteビルドアセットの配信にCloudflare R2を使用）         |
| 環境構築       | Docker                                                              |
| CI/CD | GitHub ActionsでPR時にRuboCop・Brakeman・RSpecを実行。mainマージ時に、Fly.ioへ自動デプロイ＋ViteアセットをCloudflare R2へアップロード（CDN配信）。 |
| 開発支援       | Bullet（N+1検出） / rack-mini-profiler |
| 認証           | Devise（メールログイン）/ OmniAuth（LINEログイン対応）                |
| 画像処理       | Active Storage / libvips / Cloudflare R2                                                            |
| メモエディタ   | TipTap（Reactベース WYSIWYGエディタ）                                                                        |
| 通知機能       | LINE Messaging API、ActionMailer + cron-job.org（定期メモ通知）                                   |
| 支援機能       | Stripe（寄付・マンスリーサポート）                                                                           |
| 検索・UX       | 無限スクロール（Turbo + Pagy）、オートコンプリート（書籍タイトル・著者）、フィルター・ソート機能          |
| その他         | Bootstrap / ViewComponent / Pagy                                 |

# インフラ図
[![Image from Gyazo](https://i.gyazo.com/765ddbb70bc87fe1662edf6ef1768a73.png)](https://gyazo.com/765ddbb70bc87fe1662edf6ef1768a73)


# ER図・テーブル設計
[![Image from Gyazo](https://i.gyazo.com/e2435f9a607444496d7988587d96ff05.png)](https://gyazo.com/e2435f9a607444496d7988587d96ff05)

Bokriumは、読書メモと本棚管理を中心とした構成です。  
`books`, `users`, `memos` を軸に、メモはユーザーと書籍に属する中間モデルとして設計しています。公開範囲は `visibility`（enum）で制御し、いいね機能は `like_memos` に分離しました。

タグは `user_tags` によってユーザーごとに管理し、`book_tag_assignments` により書籍と多対多の関係を構築。役割を明確に分けることで、拡張や保守をしやすくしています。

書籍画像は `images` テーブルで管理しており、1冊の本に対して複数枚のアップロードが可能です。各画像は Active Storage を通じて Cloudflare R2 に保存され、署名付きURLによる直接アップロードとCDN配信に対応しています。

通知機能は `line_users` を通じたLINE連携と、ActionMailer + cron-job.org によるメール通知に対応。支援機能としては、Stripe による単発寄付（`donations`）と継続支援（`monthly_supports`）を実装しています。

全体として、拡張性と役割の分離を重視し、成長や変更に強い構成を目指しました。
