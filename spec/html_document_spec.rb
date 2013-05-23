lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'browser_agent'
include BrowserAgent

describe HtmlDocument do
  before(:each) do
    @parser = Client.new
    @parser.get("file://" + File.expand_path(File.join(File.dirname(__FILE__),'example_document.html')))
  end

  it 'should have 3 forms' do
    @parser.form.instance_of?(Array).should == true
    @parser.form.size.should == 3

    @parser.form("test").instance_of?(FormElement).should == true
    @parser.form("notaform").instance_of?(FormElement).should == false
    @parser.form("test2").instance_of?(FormElement).should == true
    @parser.form("test3").instance_of?(FormElement).should == true
  end

  it 'the value of foo in the first form is bar' do
    @parser.form("test").foo.value.should == 'bar'
    @parser.form("test").foo.value = 'test'
    @parser.form("test").foo.value.should == 'test'
  end

  it 'first form should have 9 form elements' do
    @parser.form.first.children.size.should == 9
  end

  it 'first form should have 10 elements with javascript enabled' do
    @parser.get("file://" + File.expand_path(File.join(File.dirname(__FILE__),'example_document.html')), :javascript => true)
    @parser.form.first.children.size.should == 10
  end

  it 'first form should be a post form' do
    @parser.form.first.method.should == :post
  end

  it 'second form should be a get form' do
    @parser.form[1].method.should == :get
  end

end
