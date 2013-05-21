require 'rubygems'
require 'cookiejar'
require 'net/http'
require 'net/https'
require 'open-uri'
require File.join(File.dirname(__FILE__),'html_document')

module BrowserAgent

  class Client

    USER_AGENT = "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.0.1) Gecko/2008070208 Firefox/3.0.1"

    def initialize()
      @cookie_jar = CookieJar::Jar.new
      @domain = nil
      @current_location
      @status = nil
      @document = nil
      @scheme = 'http'
      @response = nil
    end

    def status
      @status
    end

    def scheme
      @scheme
    end

    def domain
      @domain
    end

    def domain=(val)
      if val =~ /^http/
        @domain = URI.parse(val).host
      else
        @domain = URI.parse(File.join("http://",val)).host
      end
    end

    def location
      @current_location
    end

    def path
      @current_location.split("//").last.gsub(/^([^\/]+)/,"")
    end

    def document
      @document
    end

    def response
      @response
    end

    def form(name=nil)
      @document.form(name)
    end

    def get(uri)
      fetch(uri, :method => :get)
    end

    def post(uri, params)
      fetch(uri, :method => :post, :parameters => params)
    end

    protected
    def fetch(uri, *args)
      default_options = { :method => :get, :limit => 10, :referer => nil, :debug => true }
      options = default_options.merge(args.first)

      raise ArgumentError, 'Redirect Limit Reached!' if options[:limit] <= 0
      if @domain.nil?
        raise ArgumentError, 'Invalid URL' if uri !~ /^http/
      else
        if uri !~ /^http/
          raise ArgumentError, 'Invalid URL' if uri !~ /^\//
          uri = File.join("#{@scheme}://",@domain,uri)
        end
      end

      url = URI.parse(uri)
      headers = {}
      headers['User-Agent'] = USER_AGENT
      headers['Cookie'] = @cookie_jar.get_cookie_header(uri)
      puts "#{options[:method].to_s.upcase} #{url.request_uri} -- #{headers.inspect}" if options[:debug]
      response = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
        case options[:method]
        when :post
          http.post(url.request_uri,options[:parameters],headers)
        else
          http.get(url.request_uri,headers)
        end
      end
      @current_location = response['location'] || uri
      @cookie_jar.set_cookies_from_headers(@current_location, response.to_hash)
      @status = response.code.to_i
      url = URI.parse(@current_location)
      @domain = url.host
      @scheme = url.scheme
      @response = response.body

      case response
      when Net::HTTPSuccess
        @document = HtmlDocument.new(response.body,self)
      when Net::HTTPRedirection
        fetch(response['location'], :limit => (options[:limit] - 1), :referer => uri)
      else
        response.error!
      end
    end

  end

end
