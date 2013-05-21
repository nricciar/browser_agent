module BrowserAgent

  class FormElement

    def initialize(data,doc)
      @data = data
      @doc = doc
      @children = []
      @data.traverse do |elem|
        if elem.instance_of?(Nokogiri::XML::Element)
          if ["input","select","button","textarea"].include?(elem.name)
            @children << InputElement.new(elem,self)
          end
        end
      end
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
      (@data['method'] || 'post').to_s.downcase.to_sym
    end

    def submit(name=nil)
      if name.nil?
        args = { :parameters => children.map(&:query_string).compact.join("&") }
        @doc.client.send(method, action, children.map(&:query_string).compact.join("&") )
      else
        children.each { |child| child.click() if child.name == name }
      end
    end

    def method_missing(method,*args)
      @children.each do |child|
        return child if child.name == method.to_s
      end
      super(method,*args)
    end

  end

end
