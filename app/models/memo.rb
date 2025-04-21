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
end
