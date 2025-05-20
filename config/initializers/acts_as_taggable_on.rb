ActsAsTaggableOn::Tag.class_eval do
  belongs_to :user, optional: true
end

ActsAsTaggableOn.remove_unused_tags = false
