class Memo < ApplicationRecord
  belongs_to :user
  belongs_to :book

  def memo_text
    content&.[]("text")
  end

  def memo_text=(value)
    self.content ||= {}
    self.content["text"] = value
  end

  enum :published, {
    only_i_can_see: 0,   # 非公開
    you_can_see: 1     # 公開
  }
end
