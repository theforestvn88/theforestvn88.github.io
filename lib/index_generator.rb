require_relative './html_template'

class IndexGenerator
  include HtmlTemplate

  class <<self
    def process(group_posts)
      index_html = HtmlTemplate.header

      group_posts.each do |group, posts|
        index_html += "<ul>"
        index_html += "\n"

        posts.each do |post|
          index_html += "<li>"
          index_html += "<a href=#{post[:path]}>[<span class='#{group}'>#{group.gsub('_', ' ')}</span>]#{post[:name].gsub('_', ' ')}</a>"
          index_html += "</li>"
          index_html += "\n"
        end

        index_html += "</ul>"
        index_html += "\n"
      end

      index_html += HtmlTemplate.footer
      File.delete('index.html')
      File.write('index.html', index_html)
    end
  end
end