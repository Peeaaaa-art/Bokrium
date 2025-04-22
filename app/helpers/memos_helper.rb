module MemosHelper
  def memo_dom_id(memo)
    dom_id(memo)
  end

  def memo_text(memo)
    memo.content&.fetch("text", "")
  end
end
