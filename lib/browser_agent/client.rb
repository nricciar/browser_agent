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
      @options = {}
    end

    def options
      @options
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
      ret = @current_location.split("//").last.gsub(/^([^\/]+)/,"")
      ret.nil? || ret.empty? ? "/" : ret
    end

    def document
      @document
    end

    # the actual document as returned by the server
    def response
      @response
    end

    # request all or a specific form from the document
    def form(name=nil)
      @document.form(name)
    end

    def get(uri, *options)
      fetch(uri, { :method => :get }.merge(
	options.nil? || options.first.nil? ? {} : options.first))
    end

    def post(uri, *options)
      fetch(uri, { :method => :post }.merge(
	options.nil? || options.first.nil? ? {} : options.first))
    end

    # used to include document assets like javascript files
    def fetch_asset(uri, *options)
      fetch(uri, { :method => :get, :asset => true }.merge(
	options.nil? || options.first.nil? ? {} : options.first))
    end

    protected
    def fetch(uri, *args)
      default_options = { :method => :get, :limit => 10, :referer => nil, :debug => false, 
	:asset => false, :javascript => false }
      @options = default_options.merge(args.first)

      # protect from infinite loops
      raise ArgumentError, 'Redirect Limit Reached!' if options[:limit] <= 0

      if uri =~ /^file/
        # request a html page from the local filesystem
        @current_location = uri
        @status = 200
        url = URI.parse(@current_location)
        @scheme = url.scheme
        @response = File.read(url.path)
        @domain = 'localhost'
        @document = HtmlDocument.new(@response,self)
      else
        # format //domain/path/file
        if uri =~ /^\/\/([^\/]+)\/(.*)$/
          uri = File.join("#{@scheme == 'https' ? 'https' : 'http'}://",$1,$2)
        # format /path/file with a predefined domain
        elsif uri =~ /^\// && !@domain.nil?
          uri = File.join("#{@scheme}://",@domain,uri)
        # format scheme://domain/path/file
        elsif uri =~ /^([a-z]+):\/\//
          raise ArgumentError, "Invalid Scheme '#{$1}'" unless ["http","https"].include?($1)
        # format file relative urls for internal links
        elsif !@current_location.nil? && !@domain.nil? && options[:asset]
          last_path = URI.parse(@current_location).path
          uri = File.join("#{@scheme}://",@domain,File.dirname(last_path))
        # if you make it here we do not know what to do
        # with your uri
        else
          raise ArgumentError, "Invalid URL '#{url}'"
        end
        if options[:parameters] && options[:method] == :get
          uri += (uri =~ /\?/ ? '&' : '?') + options[:parameters]
        end

        url = URI.parse(uri)

        # setup headers and cookies to impersonate a standard browser
        headers = {}
        headers['User-Agent'] = USER_AGENT
        headers['Cookie'] = @cookie_jar.get_cookie_header(uri)

        # make the server request
        response = Net::HTTP.start(url.host, url.port, :use_ssl => url.scheme == 'https', :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
          puts "#{options[:method].to_s.upcase} #{url.request_uri} -- #{headers.inspect}" if options[:debug]
          case options[:method]
          when :post
            http.post(url.request_uri,options[:parameters],headers)
          else
            http.get(url.request_uri,headers)
          end
        end

        # when making requests for included scripts and other assets do not change
        # the current location, etc...
        if options[:asset] == false
          @current_location = response['location'] || uri
          @cookie_jar.set_cookies_from_headers(@current_location, response.to_hash)
          @status = response.code.to_i
          url = URI.parse(@current_location)
          @domain = url.host
          @scheme = url.scheme
          @response = response.body
        end

        # follow any redirects and then create our html document
        case response
        when Net::HTTPSuccess
          return response.body if options[:asset]
          @document = HtmlDocument.new(response.body,self)
        when Net::HTTPRedirection
          fetch(response['location'], options.merge(:method => :get, :limit => (options[:limit] - 1), :referer => uri))
        else
          response.error!
        end
      end
    end
  end

end
