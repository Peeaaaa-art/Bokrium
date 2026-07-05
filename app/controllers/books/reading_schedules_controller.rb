class Books::ReadingSchedulesController < ApplicationController
  include ReadingRoadmap

  before_action :authenticate_user!
  before_action :set_book

  def update
    if @book.update(reading_schedule_params)
      respond_to do |format|
        format.turbo_stream do
          if roadmap_context?
            # バードラッグ後はウィンドウ・目盛り・バッジ色も変わりうるため、
            # ロードマップ全体を差し替える
            prepare_roadmap
            render turbo_stream: turbo_stream.replace(
              "roadmap_container",
              partial: "reading_board/roadmap"
            )
          else
            render turbo_stream: turbo_stream.replace(
              "reading_board_book_#{@book.id}",
              partial: "reading_board/book",
              locals: { book: @book }
            )
          end
        end
        format.html { redirect_to reading_board_path }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          if roadmap_context?
            head :unprocessable_content
          else
            flash.now[:danger] = @book.errors.full_messages.join("、")
            render turbo_stream: turbo_stream.replace(
              "reading_board_book_#{@book.id}",
              partial: "reading_board/book",
              locals: { book: @book }
            ), status: :unprocessable_content
          end
        end
        format.html { redirect_to reading_board_path, alert: @book.errors.full_messages.join("、") }
      end
    end
  end

  private

  def roadmap_context?
    params[:view_context] == "roadmap"
  end

  def set_book
    @book = current_user.books.find(params[:book_id])
  end

  def reading_schedule_params
    params.expect(book: [ :target_finish_on, :current_page, :started_on ])
  end
end
