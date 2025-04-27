class Image < ApplicationRecord
  belongs_to :book
  has_one_attached :image_path
end
