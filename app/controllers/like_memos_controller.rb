class LikeMemosController < ApplicationController
  before_action :authenticate_user!
  before_action :set_memo

  def create
    current_user.like_memos.find_or_create_by!(memo: @memo)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to shared_memo_path(@memo.public_token) }
    end
  end

  def destroy
    like = current_user.like_memos.find_by(memo: @memo)
    like&.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to shared_memo_path(@memo.public_token) }
    end
  end

  private

  def set_memo
    @memo = Memo.find_by!(public_token: params[:shared_memo_token])
  end
end
