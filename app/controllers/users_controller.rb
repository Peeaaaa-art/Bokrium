class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user, only: [ :show ]

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_path, alert: "不正なアクセスです") unless @user == current_user
  end
end
