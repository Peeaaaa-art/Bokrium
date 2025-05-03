# config/initializers/acts_as_taggable_on.rb

ActsAsTaggableOn::Tag.class_eval do
  belongs_to :user, optional: true
end