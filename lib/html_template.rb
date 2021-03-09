module HtmlTemplate
    module_function

    def header(path = nil)
        header_html = File.read('./style/header.html')
        cd_css = path.nil? ? './' : '../' * (path.split('/').count - 1)
        header_html.gsub!('href=xxx', "href='#{cd_css}style/forest.css'")
        header_html
    end
    
    def footer
        File.read('./style/footer.html')
    end
end