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

    def fetch_asset(uri)
      fetch(uri, :method => :get, :asset => true)
    end

    protected
    def fetch(uri, *args)
      default_options = { :method => :get, :limit => 10, :referer => nil, :debug => true, :asset => false }
      options = default_options.merge(args.first)

      raise ArgumentError, 'Redirect Limit Reached!' if options[:limit] <= 0
      if @domain.nil? && uri !~ /^file/
        raise ArgumentError, 'Invalid URL' if uri !~ /^http/
      else
        if uri =~ /^file/
          @current_location = uri
          @status = 200
          url = URI.parse(@current_location)
          @scheme = url.scheme
          @response = File.read(url.path)
          @domain = 'localhost'
          @document = HtmlDocument.new(@response,self)
        elsif uri =~ /^http/ || uri =~ /^\//
          uri = File.join("#{@scheme}://",@domain,uri) if uri =~ /^\//

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
          if options[:asset] == false
            @current_location = response['location'] || uri
            @cookie_jar.set_cookies_from_headers(@current_location, response.to_hash)
            @status = response.code.to_i
            url = URI.parse(@current_location)
            @domain = url.host
            @scheme = url.scheme
            @response = response.body
          end

          case response
          when Net::HTTPSuccess
            return response.body if options[:asset]
            @document = HtmlDocument.new(response.body,self)
          when Net::HTTPRedirection
            fetch(response['location'], options.merge(:limit => (options[:limit] - 1), :referer => uri))
          else
            response.error!
          end
        else
          raise ArgumentError, 'Invalid URL'
        end
      end
    end
  end

end
