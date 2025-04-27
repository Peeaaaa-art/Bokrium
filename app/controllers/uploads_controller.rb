class UploadsController < ApplicationController
  before_action :authenticate_user!

  def presigned_url
    s3 = Aws::S3::Resource.new(region: ENV["AWS_DEFAULT_REGION"])
    bucket = s3.bucket(ENV["S3_BUCKET_NAME"])

    # 保存場所をここで指定（例：uploads/user_uploads/ランダムファイル名）
    key = "uploads/#{SecureRandom.uuid}"

    obj = bucket.object(key)

    url = obj.presigned_url(:put, expires_in: 600, acl: "public-read")

    render json: { url: url, key: key }
  end
end
