module MemosHelper
  def memo_placeholder_html
    token = "PLACEHOLDER_TOKEN_9fz3!ifhdas094hfgfygq@_$2x"

    markdown_text = <<~MD
      <div data-placeholder="true" class="memo-placeholder mx-1 mx-md-5">
        <span style="display:none;">#{token}</span>
        <h3>メモを書き残しましょう</h3>
        <hr>
        <p>このエリアは <strong>マークダウン対応</strong> のリッチテキストエディタです。<br>
        あなたの読書体験や気づきを、自由に、そして丁寧に記録できます。</p>
        <p><em>※クリックするとモーダルで編集可能になります。</em></p>
      </div>
    MD

    markdown_text.html_safe
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
