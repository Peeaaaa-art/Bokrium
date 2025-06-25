ActsAsTaggableOn.remove_unused_tags = false

ActsAsTaggableOn::Tag.class_eval do
  belongs_to :user, optional: false

  validates :name, presence: true, length: { maximum: 30, message: ": タグ名は30文字以内で入力してください" }

  scope :owned_by, ->(user) { where(user_id: user.id) }
end
