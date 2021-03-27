require 'github/markup'
require 'pathname'
require_relative './html_template'
require_relative './syntax_highlighter'

class GithubMarkupConverter
  include HtmlTemplate
  include SyntaxHighlighter

  def self.convert(source:, target:)
    puts "-> converting #{source} ... "
    html = GitHub::Markup.render_s(GitHub::Markups::MARKUP_MARKDOWN, File.read(source))
    syntax_highlight_html = SyntaxHighlighter.syntax_highlighter(html)
    puts "-> writing to #{target} ... "
    output = Pathname.new(target)
    output.dirname.mkpath
    output.write(HtmlTemplate.header(target) + syntax_highlight_html + HtmlTemplate.footer)
  end
end
