require 'redcarpet'

class RedcarpetConverter
    include HtmlTemplate

    RENDERER = Redcarpet::Render::HTML.new(prettify: true, no_styles: false)
    MARKDOWN = Redcarpet::Markdown.new(RENDERER, fenced_code_blocks: true)

    def self.convert(source:, target:)
        puts "-> converting #{source} ... "
        html = MARKDOWN.render(File.read(source))
        puts "-> writing to #{target} ... "
        output = Pathname.new(target)
        output.dirname.mkpath
        output.write(HtmlTemplate.header(target) + html + HtmlTemplate.footer)
    end
end