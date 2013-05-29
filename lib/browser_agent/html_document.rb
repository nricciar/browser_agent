require File.join(File.dirname(__FILE__),'form_element')
require File.join(File.dirname(__FILE__),'input_element')

module BrowserAgent

  class HtmlDocument

    def initialize(doc,client)
      @html = doc
      @client = client

      @window = Window.new( @html )
      @window.document.location = Window::Location.new(@client.location.to_s)

      if @client.options[:javascript]
        @window.document.xpath( './/script' ).each do |script|
          if src = script['src']
            src = script['src'].to_s
            code = @client.fetch_asset(src, :javascript => true)
          else
            code = script.text
            src = :embeded
          end
          js_eval( code, src )
        end

        body = @window.document.getElementsByTagName('body')

        # call onload events
        unless body.nil? || body.empty? || body[0]['onload'].nil?
          js_eval @window.document.getElementsByTagName('body')[0].onload
        end
        js_eval "if (window.onload) { window.onload(); }"
      end

      @html = @window.document.to_html
      @doc = @window.document
    end

    def cxt
      @cxt ||= V8::Context.new( :with => @window )
    end

    def js_eval(js,src=nil)
      return unless @client.options[:javascript]
      begin
        cxt.eval( js )
      rescue Exception => e
        puts src unless src.nil?
        js.split( "\n" ).each_with_index {
            |line, i|
            puts "#{i+1} #{line}"
        }
        raise e
      end
      @html = @window.document.to_html
    end

    def to_html
      @window.document.to_html
    end

    def select(query)
      @doc.css(query)
    end

    def form(name=nil)
      ret = []
      @doc.xpath("//form").each do |form|
        tmp = FormElement.new(form,self)
        return tmp if !name.nil? && (form['id'] == name || form['name'] == name)
        ret << tmp
      end
      return nil if !name.nil?
      ret
    end

    def client
      @client
    end

  end

end
