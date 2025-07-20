# extract_bootstrap_icons.rb
require 'nokogiri'
require 'fileutils'

SRC_DIR = "/Users/hayashiakira/web_apps/icons/icons" # Bootstrap Icons SVG一式
DST_DIR = "/Users/hayashiakira/web_apps/bootstrap_bokrium_icons" # 出力先

FileUtils.mkdir_p(DST_DIR)

used_icons = Set.new

Dir.glob("app/views/**/*.erb").each do |file|
  html = File.read(file)
  doc = Nokogiri::HTML.fragment(html)

  # すべての class 属性を持つタグを対象に
  doc.css('[class]').each do |el|
    klasses = el['class'].split rescue []
    klasses.each do |k|
      if k =~ /^bi-([\w-]+)$/
        icon_name = $1
        next if used_icons.include?(icon_name)

        used_icons << icon_name

        src_path = File.join(SRC_DIR, "#{icon_name}.svg")
        dst_path = File.join(DST_DIR, "bi-#{icon_name}.svg")

        if File.exist?(src_path)
          FileUtils.cp(src_path, dst_path)
          puts "✅ Copied: #{icon_name}"
        else
          puts "⚠️ Missing: #{src_path}"
        end
      end
    end
  end
end
