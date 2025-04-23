class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  process :set_quality

  # サムネイル（小）
  version :thumb do
    process resize_to_fill: [ 200, 200 ]
  end

  # 拡大用（大）
  version :large do
    process resize_to_limit: [ 1200, 800 ]
    process :set_quality
  end

  def set_quality
    manipulate! do |img|
      img.quality "88"
      img.strip
      img.interlace "Plane"
      img
    end
  end

  # Add an allowlist of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_allowlist
    %w[jpg jpeg gif png webp avif tiff]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg"
  # end
end
