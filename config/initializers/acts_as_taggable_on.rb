ActsAsTaggableOn::Tag.class_eval do
  belongs_to :user, optional: true

  scope :owned_by, ->(user) { where(user_id: user.id) }
end

ActsAsTaggableOn.remove_unused_tags = false
