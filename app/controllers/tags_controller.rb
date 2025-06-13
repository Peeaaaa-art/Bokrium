class TagsController < ApplicationController
  before_action :set_tag, only: [ :destroy, :update, :edit ]

  def create
    @tag = current_user.tags.build(tag_params)
    if @tag.save
      flash[:info] = "タグ「#{@tag.name}」を作成しました"
      redirect_back fallback_location: root_path
    else
      error_msg = @tag.errors.full_messages.to_sentence

      if @tag.errors.details[:base].any? { |e| e[:error] == :limit_exceeded }
        render turbo_stream: limit_error_stream(id: "tag_limit_error", message: error_msg)
      else
        flash[:danger] = "タグの作成に失敗しました: " + @tag.errors.full_messages.join(", ")
        redirect_back fallback_location: root_path
      end
    end
  end

  def update
    if @tag.update(tag_params)
      flash[:info] = "タグ「#{@tag.name}」を更新しました"
      redirect_back fallback_location: root_path
    else
      flash[:danger] = "タグの更新に失敗しました: " + @tag.errors.full_messages.join(", ")
      redirect_back fallback_location: root_path
    end
  end

  def edit
  end

  def destroy
    tag_name = @tag.name
    @tag.destroy
    flash[:info] = "タグ「#{tag_name}」を削除しました"
    redirect_back fallback_location: root_path
  end


  private

  def set_tag
    @tag = current_user.tags.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :color)
  end
end
