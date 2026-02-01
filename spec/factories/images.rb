# frozen_string_literal: true

FactoryBot.define do
  factory :image do
    association :book

    after(:build) do |image|
      next if image.image_s3.attached?

      image.image_s3.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/sample.png")),
        filename: "sample.png",
        content_type: "image/png"
      )
    end
  end
end
