class Books::TagsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_book, only: [ :toggle ]

  def toggle
    respond_to do |format|
      format.turbo_stream do
        # 非同期トグル: フラッシュに頼らず、押されたタグと本詳細のバッジ一覧だけを差し替える。
        # サーバー応答で状態が確定するため、楽観的更新のロールバックは不要(常に整合)。
        BookTagToggleService.new(book: @book, user: current_user, tag_id: params[:tag_id]).call
        @tag = current_user.user_tags.find_by(id: params[:tag_id])
        @book.user_tags.reload

        if @tag
          render :toggle
        else
          head :unprocessable_content
        end
      end
      format.html do
        BookTagToggleService.new(book: @book, user: current_user, tag_id: params[:tag_id], flash: flash).call
        redirect_back fallback_location: @book
      end
    end
  end

  def filter
    render partial: "shared/filters/tag_filter", locals: {
      user_tags: current_user.user_tags.order(:id),
      filtered_tags: []
    }
  end

  private

  def set_book
    @book = current_user.books.find(params[:book_id])
  end
end
