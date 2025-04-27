class AvatarUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage Rails.env.production? ? :fog : :file
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def default_url(*args)

    "avatar_default.jpg"
  end

  version :thumb do
    process resize_to_fit: [ 100, 100 ]
  end

  def extension_allowlist
    %w[jpg jpeg gif png webp avif tiff]
  end
end
