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

  after :store_versions, :remove_original

  private
  
  def remove_original(_file)
    # モデルが保存済みの場合のみ実行（新規作成時）
    return unless model && model.persisted?
    
    # オリジナルファイルのpath
    original_file = self.file
    
    return unless original_file.present? && original_file.path.present?
    
    # バージョンファイルのpaths
    thumb_exists = versions[:thumb].present? && versions[:thumb].file.present?
    large_exists = versions[:large].present? && versions[:large].file.present?
    
    # バージョンファイルが両方存在することを確認
    if thumb_exists && large_exists
      # オリジナルファイルのファイル名
      original_filename = File.basename(original_file.path)
      
      # バージョンファイル名（thumb_xxx.jpg, large_xxx.jpg）ではないことを確認
      if !original_filename.start_with?('thumb_') && !original_filename.start_with?('large_')
        begin
          # S3上のオリジナルファイルを削除
          if original_file.store_dir.include?('uploads')
            original_file.remove! # S3上での削除処理
          else
            File.delete(original_file.path) if File.exist?(original_file.path)
          end
        rescue => e
          Rails.logger.error("Failed to delete original file: #{e.message}")
        end
      end
    end
  end
end
