class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage Rails.env.production? ? :fog : :file

  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  process :set_quality


  version :thumb do
    process resize_to_fill: [ 200, 200 ]
  end

  version :large do
    process resize_to_limit: [ 1200, 800 ]
    process :set_quality
  end

  def set_quality
    manipulate! do |img|
      img.quality "85"
      img.strip
      img.interlace "Plane"
      img
    end
  end

  def extension_allowlist
    %w[jpg jpeg gif png webp avif tiff]
  end

  after :store, :remove_original

  private

  def remove_original(file)
    # オリジナルファイルへのパス
    original_path = file.path
  
    # thumbやlargeのパスは除外
    version_paths = versions.values.map { |v| v.file.path }
  
    # オリジナルとバージョンのパスが違うなら削除
    unless version_paths.include?(original_path)
      begin
        file.delete
      rescue => e
        Rails.logger.error("Failed to delete original file: #{e.message}")
      end
    end
end
