require 'redcarpet'
require 'pathname'
require_relative './html_template'
require_relative './syntax_highlighter'

class RedcarpetConverter
  include HtmlTemplate
  include SyntaxHighlighter

  RENDERER = Redcarpet::Render::HTML.new(hard_wrap: true, filter_html: true, autolink: true, no_intraemphasis: true, fenced_code: true, gh_blockcode: true)
  MARKDOWN = Redcarpet::Markdown.new(RENDERER, fenced_code_blocks: true)

  def self.convert(source:, target:)
    puts "-> converting #{source} ... "
    html = MARKDOWN.render(File.read(source))
    syntax_highlight_html = SyntaxHighlighter.syntax_highligh(html)
    puts "-> writing to #{target} ... "
    output = Pathname.new(target)
    output.dirname.mkpath
    output.write(HtmlTemplate.header(target) + syntax_highlight_html + HtmlTemplate.footer)
  end
end