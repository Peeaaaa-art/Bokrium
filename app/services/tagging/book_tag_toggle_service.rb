# frozen_string_literal: true

module Tagging
  class BookTagToggleService
    attr_reader :book, :user, :tag_name, :flash

    def initialize(book:, user:, tag_name:, flash: {})
      @book = book
      @user = user
      @tag_name = tag_name
      @flash = flash
    end

    def call
      tag = ActsAsTaggableOn::Tag.owned_by(user).find_by(name: tag_name)

      unless tag
        flash[:danger] = "タグが見つかりません"
        return false
      end

      tagging = find_existing_tagging(tag)

      ActiveRecord::Base.transaction do
        if tagging
          tagging.destroy!
          flash[:info] = "『#{tag_name}』のタグを解除しました"
        else
          book.tag_list.add(tag.name)
          book.save!  # 保存失敗時は例外が発生
          set_tagger_for!(tag)
          flash[:info] = "『#{tag_name}』をタグ付けしました"
        end
      end

      true

    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
      flash[:danger] = "タグ操作中にエラーが発生しました: #{e.message}"
      false
    end

    private

    def find_existing_tagging(tag)
      book.taggings.find_by(
        tag_id: tag.id,
        tagger_id: user.id,
        tagger_type: "User",
        context: "tags"
      )
    end

    def set_tagger_for!(tag)
      updated = book.taggings.where(tag_id: tag.id).update_all(
        tagger_id: user.id,
        tagger_type: "User"
      )

      raise ActiveRecord::RecordInvalid.new(book), "tagの更新に失敗しました" if updated.zero?
    end
  end
end
