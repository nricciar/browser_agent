lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'browser_agent'
require File.join(File.dirname(__FILE__),'dummy_client')
include BrowserAgent

describe HtmlDocument do
  before(:each) do
    @client = DummyClient.new
    @parser = HtmlDocument.new(File.read(File.join(File.dirname(__FILE__),'example_document.html')), @client)
  end

  it 'should have 3 forms' do
    @parser.form.instance_of?(Array).should == true
    @parser.form.size.should == 3

    @parser.form("test").instance_of?(FormElement).should == true
    @parser.form("notaform").instance_of?(FormElement).should == false
    @parser.form("test2").instance_of?(FormElement).should == true
    @parser.form("test3").instance_of?(FormElement).should == true
  end

  it 'test form one submit' do
    @parser.form("test").submit()
    options = @client.options
    options[:method].should == :post
    @client.location.should == "submit.php"
    # disabled items should not be submitted
    (options[:parameters] !~ /foo=bar/).should == true
    @parser.form("test").foo.disabled = false
    @parser.form("test").submit()
    options = @client.options
    (options[:parameters] !~ /foo=bar/).should == false
    # unchecked checkboxes should not be submitted
    (options[:parameters] !~ /check1=1/).should == false
    (options[:parameters] !~ /check2=1/).should == true
    # unselected radio buttons should not be submitted
    options[:parameters] !~ /test=([0-9]+)/
    $1.should == "2"
    # clicked buttons should be submitted
    @parser.form("test").submit("submit")
    options = @client.options
    (options[:parameters] !~ /submit=Submit/).should == false
    puts @client.options.inspect
  end

  it 'the value of foo in the first form is bar' do
    @parser.form("test").foo.value.should == 'bar'
    @parser.form("test").foo.value = 'test'
    @parser.form("test").foo.value.should == 'test'
  end

  it 'first form should have 4 form elements' do
    @parser.form.first.children.size.should == 9
  end

  it 'first form should be a post form' do
    @parser.form.first.method.should == :post
  end

  it 'second form should be a get form' do
    @parser.form[1].method.should == :get
  end

end
