class ImagesController < ApplicationController
  before_action :set_book

  def create
    # 画像URLとbook_id、memo_idを含むパラメータを受け取ってImageを作成
    @image = @book.images.build(image_params)

    if @image.save
      # 成功時、JSONレスポンスを返す
      render json: { message: "画像をアップロードしました。", image: @image }, status: :created
    else
      # 失敗時、エラーレスポンスを返す
      render json: { errors: @image.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @image = @book.images.find(params[:id])
    @image.destroy
    redirect_to @book, notice: "画像を削除しました。"
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end

  def image_params
    # image_pathに加えて、memo_idを受け取るように変更
    params.require(:image).permit(:image_path, :memo_id)
  end
end