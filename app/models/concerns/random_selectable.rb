# app/models/concerns/random_selectable.rb
module RandomSelectable
  extend ActiveSupport::Concern

  class_methods do
    def random_1
      order(Arel.sql("RANDOM()")).limit(1).first
    end

    def random_9
      order(Arel.sql("RANDOM()")).limit(9)
    end
  end
end
