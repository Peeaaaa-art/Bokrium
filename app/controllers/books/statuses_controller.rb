class Books::StatusesController < ApplicationController
  include ReadingBoardColumns

  before_action :authenticate_user!
  before_action :set_book

  def update
    new_status = params.expect(book: [ :status ])[:status].to_s
    unless Book.statuses.key?(new_status)
      head :unprocessable_content and return
    end

    old_status = @book.status

    if @book.update(status: new_status)
      respond_to do |format|
        format.turbo_stream do
          # かんばんの移動元・移動先の両列を差し替える(順序・件数はサーバーが正)
          @columns = [ old_status, new_status ].uniq.map { |status| kanban_column(status) }
        end
        format.html { redirect_to reading_board_path }
      end
    else
      respond_to do |format|
        format.turbo_stream { head :unprocessable_content }
        format.html { redirect_to reading_board_path, alert: @book.errors.full_messages.join("、") }
      end
    end
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end
end
