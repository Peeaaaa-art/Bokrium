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
        error_msg = @image.errors.full_messages.to_sentence

      if @image.errors.details[:base].any? { |e| e[:error] == :limit_exceeded }
        render turbo_stream: limit_error_stream(id: "image_limit_error", message: error_msg)
      else
        flash[:danger] = "画像の保存に失敗しました：#{error_msg}"
        redirect_to @book
      end
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
