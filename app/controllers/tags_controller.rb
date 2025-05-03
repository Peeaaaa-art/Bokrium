class TagsController < ApplicationController
  before_action :set_tag, only: [ :destroy, :update, :edit ]

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

  def update
    if @tag.update(tag_params)
      redirect_back fallback_location: root_path, notice: "タグ「#{@tag.name}」を更新しました"
    else
      redirect_back fallback_location: root_path, alert: "タグの更新に失敗しました"
    end
  end

  def edit
  end

  def destroy
      @tag.destroy
      redirect_back fallback_location: root_path, notice: "タグ「#{@tag.name}」を削除しました"
  end

  private

  def set_tag
    @tag = ActsAsTaggableOn::Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :color)
  end
end
