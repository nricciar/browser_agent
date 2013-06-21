module BrowserAgent

  class FormElement

    def initialize(data,doc)
      @data = data
      @doc = doc
    end

    def document
      @doc
    end

    def name
      @data['id'] || @data['name']
    end

    def xpath(path)
      @data.xpath(path)
    end

    def action
      @data['action']
    end

    def children
      ret = []
      @data.traverse do |elem|
        if elem.instance_of?(Nokogiri::XML::Element)
          if ["input","select","button","textarea"].include?(elem.nodeName)
            ret << InputElement.new(elem,self)
          end
        end
      end
      ret
    end

    def method
      (@data['method'] || 'get').to_s.downcase.to_sym
    end

    def query_string
      children.map(&:query_string).compact.join("&")
    end

    def submit(name=nil)
      document.js_eval @data['onsubmit'] if @data['onsubmit']

      if name.nil?
        args = { :parameters => children.map(&:query_string).compact.join("&") }
        @doc.client.send(method, action, args )
      else
        children.each { |child| child.click() if child.name == name }
      end
    end

    def method_missing(method,*args)
      children.each do |child|
        return child if child.name == method.to_s
      end
      super(method,*args)
    end

  end

end
