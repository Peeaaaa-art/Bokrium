class UserTagsController < ApplicationController
  before_action :set_user_tag, only: [ :edit, :update, :destroy ]

  def create
    @user_tag = current_user.user_tags.find_or_initialize_by(name: user_tag_params[:name])
    @user_tag.color = user_tag_params[:color] if user_tag_params[:color].present?

    if @user_tag.save
      flash[:info] = "タグ「#{@user_tag.name}」を作成しました。"
    else
      flash[:danger] = "タグの作成に失敗しました: " + @user_tag.errors.full_messages.join(", ")
    end
    redirect_back fallback_location: root_path
  end

  def update
    if @user_tag.update(user_tag_params)
      flash[:info] = "タグ「#{@user_tag.name}」を更新しました。"
    else
      flash[:danger] = "タグの更新に失敗しました: " + @user_tag.errors.full_messages.join(", ")
    end
    redirect_back fallback_location: root_path
  end

  def edit
  end

  def destroy
    tag_name = @user_tag.name
    @user_tag.destroy
    flash[:info] = "タグ「#{tag_name}」を削除しました。"
    redirect_back fallback_location: root_path
  end

  private

  def set_user_tag
    @user_tag = current_user.user_tags.find(params[:id])
  end

  def user_tag_params
    params.require(:user_tag).permit(:name, :color)
  end
end
