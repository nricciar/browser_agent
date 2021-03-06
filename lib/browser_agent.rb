require 'rubygems'
require 'cookiejar'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'nokogiri'
require 'ostruct'
require 'taka'
require 'v8'

require File.join(File.dirname(__FILE__),'browser_agent/client')

#
# Monkey patch all elements to include a 'style' attribute
#
class Nokogiri::XML::Element
  attr_reader :style
 
  class Style < OpenStruct
  end
 
  def initialize( *args )
    super
    @style = Style.new
  end
end

module Taka::DOM::Document
  attr_accessor :location

  def attachEvent(event, func)
  end

  def readyState()
    proc do
      "complete"
    end
  end

  def parentNode()
    proc do
      nil
    end
  end

  def createDocumentFragment()
    proc do
      Nokogiri::XML::DocumentFragment.new(self)
    end
  end
end

module Taka::DOM::HTML::Element
  def innerHTML
    inner_html
  end

  def innerHTML=(html)
    self.native_content = html
  end
end

module BrowserAgent

  class Window

    include Taka::EventTarget if defined?(Taka::EventTarget)
    include Taka::Window::Timers if defined?(Taka::Window::Timers)

    attr_reader :document
    attr_reader :navigator
    attr_reader :readyState

    attr_accessor :location

    def attachEvent(event, func)
    end

    def initialize( html = '' )
        @document  = Taka::DOM::HTML( html )
        @navigator = Navigator.new

        @location = Location.new( '' )
        @document.location = Location.new( '' )

        ready!
    end

    def open( url )
        @document = Taka::DOM::HTML( Kernel::open( url ) )
        @document.location = @location = Location.new( url )
        ready!
        self
    end


    def alert( msg )
        puts msg
    end

    def debug( obj )
        puts obj.inspect
    end

    def window
        self
    end

    private

    def ready!
        @readyState = 'complete'
    end

  end

  class Window::Navigator
    attr_accessor :userAgent

    def initialize
        @userAgent = Client::USER_AGENT
    end

    def appVersion
      "3.0.1"
    end

  end

  class Window::Location

    def initialize( url )
        @url = URI( url )
    end

    def host
        @url.host + ':' + @url.port.to_s
    end

    def hostname
        @url.host
    end

    def href
        @url.to_s
    end

    def path
        @url.path
    end

    def port
        @url.port
    end

    def search
        '?' + @url.query
    end

    def protocol
        @url.scheme + ':'
    end

    def to_s
        @url.to_s
    end

  end

end
