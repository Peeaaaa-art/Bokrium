import { Controller } from "@hotwired/stimulus"

// Stimulusのコントローラー
export default class extends Controller {
  static targets = ["fileInput", "preview"]

  async upload() {
    const file = this.fileInputTarget.files[0];
    if (!file) {
      alert('ファイルを選択してください！');
      return;
    }

    try {
      // presigned_urlを取得
      const presignedRes = await fetch('/presigned_url', { method: 'POST' });
      const { url, key } = await presignedRes.json();

      // S3にファイルをアップロード
      await fetch(url, {
        method: 'PUT',
        headers: {
          'Content-Type': file.type
        },
        body: file
      });

      // アップロード後、公開URLをRailsに送信
      const publicUrl = url.split('?')[0];

      // ここでbook_id（またはmemo_id）を送信する
      const bookId = this.element.dataset.bookId; // HTMLでbook_idをデータ属性として渡す

      const response = await fetch(`/books/${bookId}/images`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          image: {
            image_path: publicUrl,  // S3にアップロードした画像のURL
            book_id: bookId,  // book_idを送信
          },
        }),
      });

      if (response.ok) {
        alert('画像保存に成功しました！');
        // 画像プレビュー
        this.previewTarget.src = publicUrl;
      } else {
        alert('画像保存に失敗しました');
      }
    } catch (e) {
      console.error(e);
      alert('アップロード中にエラーが発生しました');
    }
  }
}