class Books::AutocompletesController < ApplicationController
  def index
    return render json: [] unless user_signed_in?

    results = BookAutocompleteService.new(
      term: params[:term],
      scope: params[:scope],
      user: current_user
    ).call

    render json: results
  end
end
