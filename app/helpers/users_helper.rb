module UsersHelper
  def user_avatar(user, size: :large)
    image = if user.avatar_s3.attached?
              variant_for(user.avatar_s3, size)
    else
              asset_path("avatar_default.jpg")
    end
    image
  end

  private

  def variant_for(avatar, size)
    case size
    when :large
      avatar.variant(resize_to_fill: [ 400, 400 ])
    when :medium
      avatar.variant(resize_to_fill: [ 160, 160 ])
    when :small
      avatar.variant(resize_to_fill: [ 80, 80 ])
    else
      avatar.variant(resize_to_fill: [ 400, 400 ])
    end
  end
end
