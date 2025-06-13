ActsAsTaggableOn.remove_unused_tags = false

ActsAsTaggableOn::Tag.class_eval do
  belongs_to :user, optional: false

  validates :name, presence: true, length: { maximum: 30, message: ": タグ名は30文字以内で入力してください" }
  validate :within_limit_for_free_plan, on: :create

  scope :owned_by, ->(user) { where(user_id: user.id) }

  private

  def within_limit_for_free_plan
    return if user.nil? || user&.subscribed_user?

    if user.tags.count >=  BokriumLimit::FREE[:tags]
      errors.add(:base, :limit_exceeded, message: "無料プランのタグ作成上限#{BokriumLimit::FREE[:tags]}個に達しました。")
    end
  end
end
