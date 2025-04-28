// import { Controller } from "@hotwired/stimulus"

// export default class extends Controller {
//   static targets = ["fileInput", "preview"]

//   async addBookAndUpload(event) {
//     event.preventDefault();
    
//     const bookId = event.target.dataset.bookId;
//     const imageUrl = event.target.dataset.bookCoverUrl;

//     if (!bookId || !imageUrl) {
//       alert('必要な情報が足りません！');
//       return;
//     }

//     // 書影のアップロードをS3に先に行う
//     const uploadedImageUrl = await this.uploadFromUrl(imageUrl, bookId);
//     if (!uploadedImageUrl) {
//       alert('カバー画像のアップロードに失敗しました');
//       return;
//     }

//     // 書籍情報とアップロードされたカバー画像のURLをフォームにセット
//     const form = event.target.closest("form");
//     form.querySelector("input[name='book[remote_book_cover_url]']").value = uploadedImageUrl;

//     // フォームを送信
//     form.submit();
//   }

//   async uploadFromUrl(imageUrl, bookId) {
//     try {
//       const res = await fetch(imageUrl);
//       const blob = await res.blob();
//       const file = new File([blob], "cover.jpg", { type: blob.type });

//       // presigned URLを取得
//       const presignedRes = await fetch('/presigned_url', { method: 'POST' });
//       const { url, key } = await presignedRes.json();

//       // S3にアップロード
//       await fetch(url, {
//         method: 'PUT',
//         headers: {
//           'Content-Type': file.type
//         },
//         body: file
//       });

//       // アップロードされた画像の公開URLを返す
//       return url.split('?')[0];
//     } catch (e) {
//       console.error(e);
//       alert('外部画像のアップロード中にエラーが発生しました');
//       return null;
//     }
//   }
// }