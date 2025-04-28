module UsersHelper
  def user_avatar(user)
    if user.avatar.present?
      user.avatar
    else
      asset_path("avatar_default.jpg")
    end
  end
end
