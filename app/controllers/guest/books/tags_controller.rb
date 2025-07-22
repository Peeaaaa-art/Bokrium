module Guest
  module Books
    class TagsController < ApplicationController
      def filter
        render partial: "shared/filters/tag_filter", locals: {
          user_tags: guest_user.user_tags.order(:id),
          filtered_tags: []
        }
      end
    end
  end
end
