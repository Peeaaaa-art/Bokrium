class ImagesController < ApplicationController
  before_action :set_book

  def create
    @image = @book.images.build(image_params)

    if @image.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to @book }
      end
    else
      flash[:danger] = "画像の保存に失敗しました：#{@image.errors.full_messages.to_sentence}"
      redirect_to @book
    end
  end

  def destroy
    @image = @book.images.find(params[:id])
    @image.destroy
    flash[:info] = "画像を削除しました。"
    respond_to do |format|
      format.turbo_stream
      # format.html { redirect_to @book }
    end
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end

  def image_params
    params.require(:image).permit(:image_s3)
  end
end
