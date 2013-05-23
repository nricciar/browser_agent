module BrowserAgent

  class FormElement

    def initialize(data,doc)
      @data = data
      @doc = doc
      @children = []
      @data.traverse do |elem|
        if elem.instance_of?(Nokogiri::XML::Element)
          if ["input","select","button","textarea"].include?(elem.nodeName)
            @children << InputElement.new(elem,self)
          end
        end
      end
    end

    def document
      @doc
    end

    def name
      @data['id'] || @data['name']
    end

    def action
      @data['action']
    end

    def children
      @children
    end

    def method
      (@data['method'] || 'get').to_s.downcase.to_sym
    end

    def submit(name=nil)
      if @data['onsubmit']
        document.js_eval @data['onsubmit']
      end
      if name.nil?
        args = { :parameters => children.map(&:query_string).compact.join("&") }
        @doc.client.send(method, action, args )
      else
        children.each { |child| child.click() if child.name == name }
      end
    end

    def method_missing(method,*args)
#@data.traverse do |elem|
#puts elem.name
#  if ["input","select","button","textarea"].include?(elem.nodeName)
#    tmpname = elem['name'].to_s.gsub(/\[/,'_').gsub(/\]/,'')
#    puts tmpname
#    return InputElement.new(elem,self) if elem['name'].to_s.gsub(/\[/,'_').gsub(/\]/,'') == method.to_s
#  end
#end
#      puts @data.xpath(".//*[local-name()='input' or local-name()='select' or local-name()='button' or local-name()='textarea']").inspect

      @children.each do |child|
        return child if child.name == method.to_s
      end
      super(method,*args)
    end

  end

end
