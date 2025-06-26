# frozen_string_literal: true

class BookTagToggleService
  attr_reader :book, :user, :tag_id, :flash

  def initialize(book:, user:, tag_id:, flash: {})
    @book = book
    @user = user
    @tag_id = tag_id.to_i
    @flash = flash
  end

  def call
    tag = user.user_tags.find_or_create_by!(id: tag_id)
    return false unless tag

    assignment = book.book_tag_assignments.find_by(user_tag_id: tag.id, user_id: user.id)

    if assignment
      assignment.destroy!
      flash[:info] = "タグ「#{tag.name}」を解除しました"
    else
      book.book_tag_assignments.create!(user_tag_id: tag.id, user_id: user.id)
      flash[:info] = "タグ「#{tag.name}」を追加しました"
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
    flash[:danger] = "タグ操作中にエラーが発生しました: #{e.message}"
    false
  end
end
