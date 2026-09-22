require "rubygems"
require "haml"
require "sinatra"
require "linkedin"
require 'pry'

enable :sessions

helpers do
  def login?
    !session[:atoken].nil?
  end

  def profile
    linkedin_client.profile unless session[:atoken].nil?
  end

  def connections
    linkedin_client.connections unless session[:atoken].nil?
  end

  private
  def linkedin_client
    client = LinkedIn::Client.new(settings.api, settings.secret)
    client.authorize_from_access(session[:atoken], session[:asecret])
    client
  end

end

configure do
  # get your api keys at https://www.linkedin.com/secure/developer
  set :api, File.read('/etc/linkedin/client_id').strip
  set :secret, File.read('/etc/linkedin/client_secret').strip
  set :bind, '0.0.0.0'
  set :port, 1234
end

get '/affiliations' do
  # Continue here only if got "VETTED API ACCESS"
  # Like this: `account_exists = linkedin_client.profile email: 'email=lukaszgryglicki@o2.pl'`
  # Also module LinkedIn::search (discover if granted VETTED API ACCESS) 
  # https://github.com/hexgnu/linkedin
  # https://www.linkedin.com/developer/apps/5197056/auth
  binding.pry
end

get "/" do
  haml :index
end

get "/auth" do
  client = LinkedIn::Client.new(settings.api, settings.secret)
  request_token = client.request_token(:oauth_callback => "http://#{request.host}:#{request.port}/auth/callback")
  session[:rtoken] = request_token.token
  session[:rsecret] = request_token.secret

  redirect client.request_token.authorize_url
end


get "/auth/logout" do
   session[:atoken] = nil
   redirect "/"
end

get "/auth/callback" do
  client = LinkedIn::Client.new(settings.api, settings.secret)
  if session[:atoken].nil?
    pin = params[:oauth_verifier]
    atoken, asecret = client.authorize_from_request(session[:rtoken], session[:rsecret], pin)
    session[:atoken] = atoken
    session[:asecret] = asecret
  end
  redirect "/"
end


__END__
@@index
-if login?
  %p Welcome #{profile.first_name}!
  %a{:href => "/auth/logout"} Logout
  %p= profile.headline
  %br
  %a{:href => "/affiliations"} Check Affiliations
-else
  %a{:href => "/auth"} Login using LinkedIn
