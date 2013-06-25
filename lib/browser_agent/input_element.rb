module BrowserAgent

  class InputElement

    def initialize(elem,form)
      @elem = elem
      @form = form
      @name = @elem['name']
      @button_clicked = nil
    end

    def name
      @name.to_s.gsub(/\[/,'_').gsub(/\]/,'')
    end

    def elem
      @elem
    end

    def disabled?
      @elem['disabled'].nil? || !["disabled","true"].include?(@elem['disabled'].to_s.downcase) ? false : true
    end

    def disabled=(val)
      if val
        @elem['disabled'] = "disabled"
      else
        @elem.remove_attribute('disabled')
      end
    end

    def radio_button?
      @elem.nodeName == "input" && !@elem['type'].nil? && @elem['type'].downcase == "radio" ? true : false
    end

    def checkbox?
      @elem.nodeName == "input" && !@elem['type'].nil? && @elem['type'].downcase == "checkbox" ? true : false
    end

    def checked?
      @elem['checked'].nil? || !["checked","true"].include?(@elem['checked'].to_s.downcase) ? false : true
    end

    def checked=(val)
      if val
        @elem['checked'] = "checked"
      else
        @elem.remove_attribute('checked')
      end
      if radio_button? && checked?
        # uncheck all other radio buttons of the same name 
        # when one is selected
        @form.children.each do |child|
          child.checked = false if child.name == name
        end
      end
    end

    def value
      case @elem.nodeName
      when "textarea"
        @value = @elem.content
      when "select"
        opt = @elem.xpath(".//option")
        opt_val = nil
        opt.reverse.each do |o|
          opt_val = o['value'].nil? ? o.content : o['value']
          return opt_val unless o['selected'].nil? || !["selected","true"].include?(o['selected'].to_s.downcase)
        end
        opt_val.nil? ? "" : opt_val
      else
        if @elem['type'] == 'radio'
          @form.xpath('.//input[@name="' + @elem["name"] + '"]').each do |el|
            @value = el['value'] if el['checked']
          end
          @value.nil? ? @elem['value'] : @value
        else
          @value = @elem['value']
        end
      end
    end

    def valid_options
      if @elem.nodeName == "select"
        @elem.xpath('.//option').collect { |o| o['value'].nil? ? o.content : o['value'] }
      elsif @elem.nodeName == "input" && @elem["type"] == "radio"
        @form.xpath('.//input[@name="' + @elem["name"] + '"]').collect { |o| o['value'].nil? ? o.content : o['value'] }
      end
    end

    def value=(val)
      case @elem.nodeName
      when "textarea"
        @elem.content = val
      when "select"
        @elem.xpath('.//option').each do |o| 
          if o['value'] == val.to_s
            o['selected'] = 'selected'
          else
            o.remove_attribute('selected')
          end
        end
      else
        if @elem['type'] == 'radio'
          @form.children.each do |child|
            if child.name == self.name
              if child.elem['value'] == val.to_s
                child.elem['checked'] = "checked"
              else
                child.elem.remove_attribute('checked')
              end
            end
          end
        else
          @elem['value'] = val
        end
      end
      if @elem['onchange']
        @form.document.js_eval @elem['onchange']
      end
    end

    def query_string
      if ["input","textarea"].include?(@elem.nodeName)
        return nil if ["submit","button"].include?(@elem['type']) && @elem['_clicked'].nil?
        escape("#{@elem['name']}")+"="+escape("#{value}") unless disabled? || ((checkbox? || radio_button?) && !checked?)
      elsif @elem.nodeName == "select"
        escape("#{@elem['name']}")+"="+escape("#{value}") unless disabled? || ((checkbox? || radio_button?) && !checked?)
      else
        nil
      end
    end

    def click
      @form.document.js_eval @elem['onmousedown'] if @elem['onmousedown']
      @form.document.js_eval @elem['onclick'] if @elem['onclick']
      @form.document.js_eval @elem['onmouseup'] if @elem['onmouseup']

      if (@elem.nodeName == "input" && ["submit","image"].include?(@elem['type'])) || @elem.nodeName == "button"
        @elem['_clicked'] = 'clicked'
        @form.submit()
        @elem.remove_attribute('_clicked')
      end
    end

    protected
    def escape(s)
      s.to_s.gsub(/([^ a-zA-Z0-9_.-]+)/n) {
        '%'+$1.unpack('H2'*bytesize($1)).join('%').upcase
      }.tr(' ', '+')
    end

    def bytesize(string)
      string.bytesize
    end

  end

end
