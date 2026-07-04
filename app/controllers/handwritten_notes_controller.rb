class HandwrittenNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book
  before_action :set_handwritten_note, only: [ :show, :update, :destroy, :thumbnail ]

  def create
    next_position = (@book.handwritten_notes.maximum(:position) || -1) + 1
    note = @book.handwritten_notes.create!(user: current_user, data: {}, position: next_position)
    redirect_to book_handwritten_note_path(@book, note)
  end

  def show; end

  def update
    if @handwritten_note.update(handwritten_note_attributes)
      head :no_content
    else
      render json: { errors: @handwritten_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @handwritten_note.destroy
    flash[:info] = "手書きノートを削除しました。"
    redirect_to book_path(@book), status: :see_other
  end

  def thumbnail
    file = params[:thumbnail]
    unless file.is_a?(ActionDispatch::Http::UploadedFile)
      raise ActionController::BadRequest, "thumbnail file is required"
    end

    @handwritten_note.thumbnail_s3.attach(file)
    if @handwritten_note.valid?
      head :no_content
    else
      render json: { errors: @handwritten_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end

  def set_handwritten_note
    @handwritten_note = @book.handwritten_notes.find(params[:id])
  end

  # Excalidrawのシーンは任意のキーを持つJSONのため、Strong Parametersは通さず
  # ボディを直接パースする。dataはjsonbカラムにのみ代入され、
  # サイズ上限はモデル側で検証する
  def handwritten_note_attributes
    body = JSON.parse(request.raw_post)
    payload = body.is_a?(Hash) ? body["handwritten_note"] : nil
    raise ActionController::BadRequest, "handwritten_note must be an object" unless payload.is_a?(Hash)

    attributes = {}
    if payload.key?("data")
      raise ActionController::BadRequest, "data must be an object" unless payload["data"].is_a?(Hash)

      attributes[:data] = payload["data"]
    end
    if payload.key?("title")
      title = payload["title"]
      raise ActionController::BadRequest, "title must be a string" unless title.nil? || title.is_a?(String)

      attributes[:title] = title&.strip.presence
    end
    raise ActionController::BadRequest, "nothing to update" if attributes.empty?

    attributes
  rescue JSON::ParserError
    raise ActionController::BadRequest, "request body must be JSON"
  end
end
