require File.join(File.dirname(__FILE__),'form_element')
require File.join(File.dirname(__FILE__),'input_element')

module BrowserAgent

  class HtmlDocument

    def initialize(doc,client)
      @html = doc
      @client = client

      @window = Window.new( @html )
      @window.document.location = Window::Location.new(@client.location.to_s)

      @cxt = V8::Context.new( :with => @window )
      @window.document.xpath( './/script' ).each do |script|
        if src = script['src']
          src = script['src'].to_s
          code = @client.fetch_asset(src)
#          code = IO.read( open( src ) )
        else
          code = script.text
          src = 'EMBEDED'
        end

        begin
          @cxt.eval( code )
        rescue Exception => e
          puts src
          code.split( "\n" ).each_with_index {
              |line, i|
              puts "#{i+1} #{line}"
          }
          raise e
        end
      end

      body = @window.document.getElementsByTagName('body')

      # call onload events
      unless body.nil? || body.empty? || body[0]['onload'].nil?
        @cxt.eval @window.document.getElementsByTagName('body')[0].onload
      end
      @cxt.eval "if (window.onload) { window.onload(); }"

      @html = @window.document.to_html
      @doc = @window.document
    end

    def js_eval(js)
      @cxt.eval js
      @html = @window.document.to_html
      @doc = @window.document
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
