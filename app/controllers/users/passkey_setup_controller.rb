# frozen_string_literal: true

module Users
  class PasskeySetupController < ApplicationController
    before_action :authenticate_user!

    def show
      # パスキーが既に登録されている場合はマイページへ
      if current_user.credentials.any?
        redirect_to mypage_path, notice: "パスキーは既に登録されています。"
      end
    end

    def complete
      # パスキー登録完了後、スターターガイドへ
      redirect_to guest_starter_books_path, notice: "パスキーの設定が完了しました！"
    end

    def skip
      # スキップしてスターターガイドへ
      redirect_to guest_starter_books_path, notice: "パスキーの設定をスキップしました。後からマイページで設定できます。"
    end
  end
end
