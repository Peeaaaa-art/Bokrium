class Donation < ApplicationRecord
  belongs_to :user, optional: true # 非ログインユーザーの寄付にも対応
end
