class WelcomeController < ApplicationController
  def index
    @random_memo = current_user&.memos&.includes(:book)&.order("RANDOM()")&.first

    @others_random_memo =
    Memo.includes(:book, user: { avatar_s3_attachment: :blob })
        .where(published: :you_can_see)
        .order("RANDOM()")
        .first
  end
end
