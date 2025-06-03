module BooksHelper
  def bookshelf_sample_notice
    return if user_signed_in? && !current_user.books.exists?
    return unless !user_signed_in? || @read_only

    content_tag :div, class: "alert-bokrium-info d-flex align-items-center text-center py-2 py-md-3" do
      content_tag :div, class: "container text-center text-sample" do
        concat content_tag(:i, nil, class: "bi bi-info-circle-fill fs-6 me-2")
        concat "こちらはサンプル表示です。自分の本棚をつくるためには、"
        concat link_to("ログイン", new_user_session_path)
        concat "・"
        concat link_to("アカウント登録", new_user_registration_path)
        concat "が必要です。"
      end
    end
  end

  def empty_bookshelf_notice
    return unless user_signed_in?
    return if current_user&.books&.exists?

    content_tag :div,
      class: "alert-bokrium-info d-flex align-items-center text-center py-2 py-md-3" do
      content_tag :div, class: "container text-center text-sample" do
        concat content_tag(:i, nil, class: "bi bi-info-circle-fill fs-6 me-2")
        concat "こちらはサンプル表示です。"
        concat link_to("最初の本を登録", search_books_path)
        concat "しましょう！"
      end
    end
  end
end
