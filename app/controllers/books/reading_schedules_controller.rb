class Books::ReadingSchedulesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book

  def update
    if @book.update(reading_schedule_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "reading_board_book_#{@book.id}",
            partial: "reading_board/book",
            locals: { book: @book }
          )
        end
        format.html { redirect_to reading_board_path }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          flash.now[:danger] = @book.errors.full_messages.join("、")
          render turbo_stream: turbo_stream.replace(
            "reading_board_book_#{@book.id}",
            partial: "reading_board/book",
            locals: { book: @book }
          ), status: :unprocessable_entity
        end
        format.html { redirect_to reading_board_path, alert: @book.errors.full_messages.join("、") }
      end
    end
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end

  def reading_schedule_params
    params.expect(book: [ :target_finish_on, :current_page, :started_on ])
  end
end
