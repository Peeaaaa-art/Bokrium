class MemoMailer < ApplicationMailer
  def random_memo_email(user, memo)
    @user = user
    @memo = memo
    @book = memo.book
    @html_content = @memo.content.to_s # ← Redcarpet不要！

    mail(
      to: @user.email,
      subject: "今日のあなたのメモ『#{@book.title.presence || '無題の本'}』より"
    )
  end
end
