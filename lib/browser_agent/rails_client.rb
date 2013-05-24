module BrowserAgent

  class RailsClient < Client

    protected
    def fetch(uri, *args)
      default_options = { :method => :get, :limit => 10, :referer => nil, :debug => false }
      options = default_options.merge(args.first)
      if uri =~ /^\// && !@domain.nil?
        uri = File.join("#{@scheme}://",@domain,uri)
      end
      @current_location = uri

      headers = {}
      headers['User-Agent'] = USER_AGENT
      headers['Cookie'] = @cookie_jar.get_cookie_header(uri)

      puts "#{options[:method].to_s.upcase} #{uri} -- #{headers.inspect}"

      route = Rails.application.routes.recognize_path(path, :method => options[:method])
      env = Rack::MockRequest.env_for(uri, :params => route, 'HTTP_HOST' => @domain)
      controllerClass = "#{route[:controller]}_controller".camelize.constantize
      endpoint = controllerClass.action(route[:action])
      @status, headers, response = endpoint.call(env)

      @current_location = headers['location'] || uri
      @cookie_jar.set_cookies_from_headers(@current_location, headers)
      @response = response.body
      @scheme = response.request.env["rack.url_scheme"]

      case @status
      when 200
        @document = HtmlDocument.new(response.body, self)
      when 301..302
        loc = headers["Location"]
        fetch(loc, :limit => (options[:limit] - 1), :referer => uri)
      end
    end

  end

end
