# app/controllers/guest/books/autocompletes_controller.rb
module Guest
  module Books
    class AutocompletesController < ApplicationController
      def index
        results = BookAutocompleteService.new(
          term: params[:term],
          scope: "guest",
          user: guest_user
        ).call

        render json: results
      end
    end
  end
end
