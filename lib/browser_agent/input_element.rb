module BrowserAgent

  class InputElement

    def initialize(elem,form)
      @elem = elem
      @form = form
      @name = @elem['name']
      case @elem.name
      when "textarea"
        @value = @elem.content
      else
        @value = @elem['value']
      end
      @disabled = @elem['disabled'].nil? || !["disabled","true"].include?(@elem['disabled'].to_s.downcase) ? false : true
      if checkbox? || radio_button?
        @checked = @elem['checked'].nil? || !["checked","true"].include?(@elem['checked'].to_s.downcase) ? false : true
      else
        @checked = nil
      end
      @button_clicked = nil
    end

    def name
      @name.to_s.gsub(/\[/,'_').gsub(/\]/,'')
    end

    def disabled?
      @disabled
    end

    def disabled=(val)
      @disabled = val == true ? true : false
    end

    def radio_button?
      @elem.name == "input" && !@elem['type'].nil? && @elem['type'].downcase == "radio" ? true : false
    end

    def checkbox?
      @elem.name == "input" && !@elem['type'].nil? && @elem['type'].downcase == "checkbox" ? true : false
    end

    def checked?
      @checked
    end

    def checked=(val)
      @checked = val == true ? true : false
      if radio_button? && @checked == true
        # uncheck all other radio buttons of the same name 
        # when one is selected
        @form.children.each do |child|
          child.checked = false if child.name == name
        end
      end
    end

    def value
      @value.to_s
    end

    def value=(val)
      @value = val
    end

    def escaped_value
      value.gsub(/\+/,'%2B')
    end

    def query_string
      if @elem.name == "input"
        return nil if ["submit","button"].include?(@elem['type']) && @button_clicked.nil?
        URI::escape("#{@elem['name']}=#{escaped_value}") unless disabled? || ((checkbox? || radio_button?) && !checked?)
      else
        nil
      end
    end

    def click
      if (@elem.name == "input" && ["submit","image"].include?(@elem['type'])) || @elem.name == "button"
        @button_clicked = true
        @form.submit()
        @button_clicked = nil
      end
    end

  end

end
