import { Controller } from "@hotwired/stimulus"

// connectするだけで使える！
export default class extends Controller {
  static targets = ["fileInput", "preview"]

  async upload() {
    const file = this.fileInputTarget.files[0];
    if (!file) {
      alert('ファイルを選択してください！');
      return;
    }

    try {
      const presignedRes = await fetch('/presigned_url', { method: 'POST' });
      const { url, key } = await presignedRes.json();

      await fetch(url, {
        method: 'PUT',
        headers: {
          'Content-Type': file.type
        },
        body: file
      });

      const publicUrl = url.split('?')[0];
      this.previewTarget.src = publicUrl;

      alert('アップロード成功！');

    } catch (e) {
      console.error(e);
      alert('アップロード失敗');
    }
  }
}