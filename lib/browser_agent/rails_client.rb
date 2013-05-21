module BrowserAgent

  class RailsClient < Client

    protected
    def fetch(uri, *args)
      default_options = { :method => :get, :limit => 10, :referer => nil, :debug => false }
      options = default_options.merge(args.first)
      @current_location = uri

      route = Rails.application.routes.recognize_path(path, :method => options[:method])
      env = Rack::MockRequest.env_for(uri, :params => route, 'HTTP_HOST' => @domain)
      controllerClass = "#{route[:controller]}_controller".camelize.constantize
      endpoint = controllerClass.action(route[:action])
      @status, headers, body = endpoint.call(env)

      case @status
      when 200
      when 302
        loc = headers["Location"]
        fetch(loc, :limit => (options[:limit] - 1), :referer => uri)
      when 301
      end
      puts "#{@status.inspect} -- #{headers.inspect}"
      puts "#{uri} -- #{args.inspect}"
    end

  end

end
