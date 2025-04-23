class Image < ApplicationRecord
  belongs_to :book
  mount_uploader :image_path, ImageUploader
end
