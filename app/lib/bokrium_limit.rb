module BokriumLimit
  FREE = {
    memos: 100,
    books: 100,
    tags: 10,
    images: 10,
    random_notifications: 5
  }.freeze

  PREMIUM = {
    memos: Float::INFINITY,
    books: Float::INFINITY,
    tags: Float::INFINITY,
    images: Float::INFINITY,
    random_notifications: Float::INFINITY
  }.freeze

  def self.for(user)
    user.bokrium_premium? ? PREMIUM : FREE
  end
end
