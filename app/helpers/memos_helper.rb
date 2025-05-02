module MemosHelper
  def memo_placeholder_html
    markdown_text = <<~MD
    ### メモを書き残しましょう

    ---
    このエリアは **マークダウン対応** のリッチテキストエディタです。
    あなたの読書体験や気づきを、自由に、そして丁寧に記録できます。

    **クリックするとモーダルで編集可能になります。**

    MD


    markdown_to_html(markdown_text).html_safe
  end

  def how_to_use_tiptap_editor
    markdown_text = <<~MD
    ### 📖 使い方のヒント

    - `**強調**` → **強調されたテキスト**
    - `_斜体_` → *斜体*
    - `- 箇条書き` でリストが作れます
    - `> 引用文` で引用ブロックに
    - `` `コード` `` でインラインコードに

    > 記録することで、読書が「対話」になります。
    MD
    markdown_to_html(markdown_text).html_safe
  end

  def markdown_to_html(text)
    renderer = Redcarpet::Render::HTML.new(filter_html: true, hard_wrap: true)
    markdown = Redcarpet::Markdown.new(renderer, autolink: true, tables: true)
    markdown.render(text)
  end
end
