class DummyClient

  def delete(uri)
    fetch(uri, :method => :delete)
  end

  def put(uri,params)
    fetch(uri, :method => :put, :parameters => params)
  end

  def get(uri)
    fetch(uri, :method => :get)
  end

  def post(uri, params)
    fetch(uri, :method => :post, :parameters => params)
  end

  def location
    @location
  end

  def options
    @options ||= {}
  end

  protected
  def fetch(uri, *args)
    default_options = { :method => :get, :limit => 10, :referer => nil }
    @options = default_options.merge(args.first)
    @location = uri
  end

end
