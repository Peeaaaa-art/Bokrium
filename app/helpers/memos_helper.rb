module MemosHelper
  def memo_text(memo)
    memo.content&.fetch("text", "")
  end
end
