---
name: verify
description: 変更をBokriumの実アプリで動かしてエンドツーエンドで確認する手順。devサーバー起動、テストユーザー、ログイン、主要画面の導線、iPad実機確認、本番相当アセットでの確認。
---

# Bokriumの動作確認

## 起動

```sh
docker compose run --rm web bundle exec rails db:prepare   # そのworktreeで初回のみ
docker compose up web    # バックグラウンドで起動(Rails:3000 + Vite:3036)
```

`curl -s http://localhost:3000/up` が200を返すまで待つ(初回は1分程度)。

## テストデータ

devデータベースはworktreeごとに独立している。検証用ユーザーと本を冪等に作る:

```sh
docker compose run --rm web bundle exec rails runner "
u = User.find_or_create_by!(email: 'dev@example.com') { |x| x.password = 'password123'; x.password_confirmation = 'password123'; x.confirmed_at = Time.current }
b = Book.find_or_create_by!(user: u, title: '検証用の本') { |x| x.status = :want_to_read }
puts \"user=#{u.id} book=#{b.id}\""
```

## ブラウザでの確認

- ログイン: `/users/sign_in` に `dev@example.com` / `password123`
  - 1Password拡張のアイコンが入力欄の右端に被ってクリックを吸うことがある。**フィールドの左寄りをクリック**する。空フォームで送信されてしまったら座標クリックで再入力
- 主要画面: `/books`(本棚)、`/books/:id`(本詳細。ツールバーにタグ/画像/手書きノート/設定)、`/books/:id/handwritten_note`(Excalidraw手書きノート)
- サーバーログ: `docker compose logs web --since 5m`。**ブラウザ拡張のネットワーク表示は204レスポンスを503と誤表示することがある — サーバーログを正とする**
- Turbo遷移とフルリロードの両方で確認する(マウント/復元のバグはTurbo遷移でだけ出ることがある)

## 本番相当アセットでの確認(体感性能を見るとき)

開発ビルドはReact/依存ライブラリが遅い開発版になるため、描画性能などの体感はあてにならない。本番相当で確認するには:

```sh
docker compose stop
docker compose run --rm -e NODE_ENV=production web bin/vite build   # public/vite-devへ出力
docker compose run --rm --service-ports web bundle exec rails server -b 0.0.0.0 -p 3000
```

Vite devサーバーが不在だとvite_rubyがビルド済みマニフェスト配信にフォールバックする。

## iPad等の実機確認

- MacのLAN IP(`ipconfig getifaddr en0`)を使い、同一Wi-Fiから `http://{IP}:3000`
- RailsはIPアドレスでのアクセスをデフォルト許可(ホスト名と違い設定不要)
- Apple Pencilの書き味を見るときはiPadの**低電力モードをオフ**にする(サンプリングレートが落ちる)

## 片付け

```sh
docker compose down
```
