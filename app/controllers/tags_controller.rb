class TagsController < ApplicationController
  def create
    @tags = ActsAsTaggableOn::Tag.all.order(created_at: :desc)
    tag = ActsAsTaggableOn::Tag.new(tag_params)
    tag.user = current_user
    if tag.save
      redirect_back fallback_location: root_path, notice: "タグを作成しました"
    else
      redirect_back fallback_location: root_path, alert: "タグの作成に失敗しました"
    end
  end
  private

  def tag_params
    params.require(:tag).permit(:name, :color)
  end
end