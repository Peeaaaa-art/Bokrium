# かんばん列の並び確定エンドポイント。ドロップ後の列の並び(ordered_ids)を
# 丸ごと受け取り、status と board_position を一括更新する。
# 同一列内の並び替えも、列間移動(ドロップ位置保持)も、これ1本で処理する
class ReadingBoard::ColumnsController < ApplicationController
  include ReadingBoardColumns

  before_action :authenticate_user!

  def update
    status = params[:status].to_s
    head :unprocessable_content and return unless Book.statuses.key?(status)

    ids = Array(params.permit(ordered_ids: [])[:ordered_ids]).map(&:to_i)
    head :unprocessable_content and return if ids.empty?

    # save!時のバリデーションが書影attachmentを参照するため、まとめて読み込む
    books = current_user.books.with_attached_book_cover_s3.where(id: ids).index_by(&:id)
    # 他ユーザーの本や存在しないidが混ざっていたら何も変更しない
    raise ActiveRecord::RecordNotFound unless ids.all? { |id| books.key?(id) }

    old_statuses = books.values.map(&:status).uniq

    Book.transaction do
      ids.each_with_index do |id, index|
        book = books[id]
        book.status = status
        book.board_position = index
        book.save!
      end
    end

    @columns = (old_statuses + [ status ]).uniq.map { |s| kanban_column(s) }
  rescue ActiveRecord::RecordInvalid
    head :unprocessable_content
  end
end
