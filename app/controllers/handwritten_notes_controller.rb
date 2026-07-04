class HandwrittenNotesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book
  before_action :set_handwritten_note

  def show; end

  def update
    if @handwritten_note.update(data: handwritten_note_data)
      head :no_content
    else
      render json: { errors: @handwritten_note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end

  # Phase 1では1冊につき1ノート。初回アクセス時に空ノートを作る
  def set_handwritten_note
    @handwritten_note = @book.handwritten_notes.order(:position, :id).first ||
                        @book.handwritten_notes.create!(user: current_user, data: {})
  end

  # Excalidrawのシーンは任意のキーを持つJSONのため、Strong Parametersは通さず
  # ボディを直接パースする。dataはjsonbカラムにのみ代入され、
  # サイズ上限はモデル側で検証する
  def handwritten_note_data
    body = JSON.parse(request.raw_post)
    data = body.is_a?(Hash) ? body.dig("handwritten_note", "data") : nil
    raise ActionController::BadRequest, "data must be an object" unless data.is_a?(Hash)

    data
  rescue JSON::ParserError
    raise ActionController::BadRequest, "request body must be JSON"
  end
end
