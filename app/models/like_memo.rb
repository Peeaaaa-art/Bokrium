class LikeMemo < ApplicationRecord
  belongs_to :user
  belongs_to :memo
end
