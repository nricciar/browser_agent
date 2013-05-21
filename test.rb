lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'browser_agent'

client = BrowserAgent::Client.new
client.domain = "192.168.15.172"
client.get('/users/account/')
puts client.location
form = client.form('login-form')
form.user_email.value = "nricciar@gmail.com"
form.user_password.value = "aqrt7943"
form.submit()
client.get("/users/account/")
puts client.location
