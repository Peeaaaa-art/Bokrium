# frozen_string_literal: true

class BookOgImageSvg
  WIDTH = 1200
  HEIGHT = 630
  COVER_WIDTH = 330
  COVER_HEIGHT = 500
  COVER_X = (WIDTH - COVER_WIDTH) / 2
  COVER_Y = 64
  BAND_HEIGHT = 52
  MAX_LINES = 8

  def initialize(book)
    @book = book
  end

  def call
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{WIDTH}" height="#{HEIGHT}" viewBox="0 0 #{WIDTH} #{HEIGHT}" role="img" aria-label="#{escape(title)}">
        <rect width="#{WIDTH}" height="#{HEIGHT}" fill="#f7f1df"/>
        <rect x="#{COVER_X - 26}" y="#{COVER_Y - 24}" width="#{COVER_WIDTH + 52}" height="#{COVER_HEIGHT + 48}" rx="28" fill="#000" opacity="0.08"/>
        <g filter="url(#shadow)">
          <rect x="#{COVER_X}" y="#{COVER_Y}" width="#{COVER_WIDTH}" height="#{COVER_HEIGHT}" rx="8" fill="#f1c94b"/>
          #{title_lines_svg}
          <rect x="#{COVER_X}" y="#{COVER_Y + COVER_HEIGHT - BAND_HEIGHT}" width="#{COVER_WIDTH}" height="#{BAND_HEIGHT}" rx="8" fill="#333333"/>
          <rect x="#{COVER_X}" y="#{COVER_Y + COVER_HEIGHT - BAND_HEIGHT}" width="#{COVER_WIDTH}" height="8" fill="#333333"/>
          <text x="#{COVER_X + COVER_WIDTH - 22}" y="#{COVER_Y + COVER_HEIGHT - 18}" text-anchor="end" font-family="Arial, 'Noto Sans JP', sans-serif" font-size="25" font-weight="700" fill="#ffffff" letter-spacing="1.2">Bokrium</text>
        </g>
        <defs>
          <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
            <feDropShadow dx="0" dy="18" stdDeviation="16" flood-color="#000000" flood-opacity="0.24"/>
          </filter>
        </defs>
      </svg>
    SVG
  end

  private

  attr_reader :book

  def title
    book.title.presence || "無題の本"
  end

  def title_lines_svg
    lines = wrapped_title_lines
    line_height = lines.size >= 7 ? 34 : 40
    font_size = lines.size >= 7 ? 27 : 31
    total_height = (lines.size - 1) * line_height
    content_top = COVER_Y + 44
    content_bottom = COVER_Y + COVER_HEIGHT - BAND_HEIGHT - 34
    start_y = content_top + ((content_bottom - content_top - total_height) / 2)

    lines.each_with_index.map do |line, index|
      %(<text x="#{COVER_X + COVER_WIDTH / 2}" y="#{start_y + (index * line_height)}" text-anchor="middle" font-family="'Noto Sans JP', Arial, sans-serif" font-size="#{font_size}" font-weight="700" fill="#111111">#{escape(line)}</text>)
    end.join("\n          ")
  end

  def wrapped_title_lines
    lines = []
    current = ""
    current_width = 0.0
    max_width = 8.8

    title.each_char do |char|
      char_width = char.ascii_only? ? 0.55 : 1.0

      if current_width.positive? && current_width + char_width > max_width
        lines << current
        current = ""
        current_width = 0.0
        break if lines.size == MAX_LINES
      end

      current << char
      current_width += char_width
    end

    lines << current if current.present? && lines.size < MAX_LINES

    if lines.size == MAX_LINES && lines.join.length < title.length
      lines[-1] = "#{lines[-1].chars[0...-1].join}…"
    end

    lines
  end

  def escape(value)
    ERB::Util.html_escape(value)
  end
end
