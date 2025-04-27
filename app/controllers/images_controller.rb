class ImagesController < ApplicationController
  before_action :set_book

  def create
    @image = @book.images.build(image_params)

    if @image.save
      respond_to do |format|
        format.html { redirect_to @book, notice: "画像をアップロードしました。" }
        format.turbo_stream # Turbo Streamレスポンスを返す
      end
    else
      redirect_to @book, alert: "画像のアップロードに失敗しました。"
    end
  end

  def destroy
    @image = @book.images.find(params[:id])
    @image.destroy
    respond_to do |format|
      format.html { redirect_to @book, notice: "画像を削除しました。" }
      format.turbo_stream # Turbo Streamレスポンスを返す
    end
  end

  private

  def set_book
    @book = Book.find(params[:book_id])
  end

  def image_params
    params.require(:image).permit(:image_path)
  end
end