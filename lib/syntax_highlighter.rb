require 'nokogiri'
require 'albino'

module SyntaxHighlighter
  module_function

  def syntax_highligh(html)
    doc = Nokogiri::HTML(html)
    doc.search("//pre").each do |pre|
      code = pre.search("//code[@class]").first
      lang = code[:class] unless code.nil?
      code = Albino.colorize(pre.text.rstrip, lang || 'ruby')
      pre.inner_html = code[28 .. -13]
    end
    doc.to_html
  end
end
