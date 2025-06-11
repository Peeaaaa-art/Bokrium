class LineUser < ApplicationRecord
  belongs_to :user

  validates :line_id, uniqueness: true, allow_nil: true
end
