# app/models/concerns/random_selectable.rb
module RandomSelectable
  extend ActiveSupport::Concern

  class_methods do
    def random_one
      order(Arel.sql("RANDOM()")).first
    end
  end
end
