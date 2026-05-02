class MemoMailer < ApplicationMailer
  helper MemosHelper

  def random_memo_email(user, memo)
    @user = user
    @memo = memo
    @book = memo.book

    mail(
      to: @user.email,
      subject: "今日のあなたのメモ『#{@book.title.presence || '無題の本'}』より"
    )
  end
end
