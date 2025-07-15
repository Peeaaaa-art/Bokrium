class ViewModesController < ApplicationController
  VALID_VIEWS = %w[shelf spine card detail_card b_note].freeze

  def update
    if VALID_VIEWS.include?(params[:view])
      session[:view_mode] = params[:view]
    end
    redirect_to books_index_path
  end
end
