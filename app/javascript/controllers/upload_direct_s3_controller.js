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

    await this.uploadFile(file);
  }

  // ファイルオブジェクトを受け取ってアップロードする共通処理
  async uploadFile(file, bookId = null) {
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

      // bookIdが渡されていなければ、data属性から取得
      if (!bookId) {
        bookId = this.element.dataset.bookId;
      }

      const response = await fetch(`/books/${bookId}/images`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          image: {
            image_path: publicUrl,
            book_id: bookId,
          },
        }),
      });

      if (response.ok) {
        alert('画像保存に成功しました！');
        if (this.hasPreviewTarget) {
          this.previewTarget.src = publicUrl;
        }
      } else {
        alert('画像保存に失敗しました');
      }
    } catch (e) {
      console.error(e);
      alert('アップロード中にエラーが発生しました');
    }
  }

  // 外部画像URLを直接アップロードするための新しいメソッド
  async uploadFromUrl(imageUrl, bookId) {
    try {
      const res = await fetch(imageUrl);
      const blob = await res.blob();
      const file = new File([blob], "cover.jpg", { type: blob.type });

      await this.uploadFile(file, bookId);
    } catch (e) {
      console.error(e);
      alert('外部画像のアップロード中にエラーが発生しました');
    }
  }

  async addBookAndUpload(event) {
    event.preventDefault();
  
    const bookId = event.target.dataset.bookId;
    const imageUrl = event.target.dataset.bookCoverUrl;
  
    if (!bookId || !imageUrl) {
      alert('必要な情報が足りません！');
      return;
    }
  
    await this.uploadFromUrl(imageUrl, bookId);
  
    // 画像アップロードが成功したら本棚に追加するリクエストを送る
    event.target.form.submit(); 
  }
}