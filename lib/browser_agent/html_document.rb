require File.join(File.dirname(__FILE__),'form_element')
require File.join(File.dirname(__FILE__),'input_element')
require 'nokogiri'

module BrowserAgent

  class HtmlDocument

    def initialize(doc,client)
      @html = doc
      @client = client
      @doc = Nokogiri::HTML(@html)
      @forms = []
      @doc.xpath("//form").each { |form| @forms << FormElement.new(form,self) }
    end

    def select(query)
      @doc.css(query)
    end

    def form(name=nil)
      if name.nil?
        @forms
      else
        @forms.each { |form| return form if form.name == name }
        nil
      end
    end

    def client
      @client
    end

  end

end
