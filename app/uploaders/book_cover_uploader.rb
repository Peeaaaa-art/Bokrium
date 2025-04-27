class BookCoverUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage Rails.env.production? ? :fog : :file
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  def default_url(*args)
    ActionController::Base.helpers.asset_path("optimized1.jpg")
  end

    process :resize

    def resize
      manipulate! do |img|
        img.resize "240x"
        img.strip
        img.interlace "Plane"
        img
      end
    end

  def extension_allowlist
    %w[jpg jpeg gif png webp avif tiff]
  end
end
