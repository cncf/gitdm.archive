require 'pry'
require 'octokit'

# It tries to call GitHub only twice per repo (general repo data & commits), then saves data JSON to files
# If file is saved (2 per repo) - it is read isnstead of quering GitHub
def rate_limit()
  rl = Octokit.rate_limit
  puts "Your rate limit is: limit=#{rl.limit}, remaining=#{rl.remaining}, resets_at=#{rl.resets_at}, resets_in=#{rl.resets_in}"
  (rl.resets_at - Time.now).to_i + 1
end

def octokit_init()
  # Auto paginate results, this uses maximum page size 100 internally and calls API # of results / 100 times.
  Octokit.auto_paginate = true

  # Login with standard OAuth token
  # https://github.com/settings/tokens --> Personal access tokens
  client = Octokit::Client.new access_token: File.read('/etc/github/oauth').strip
  user = client.user
  user.login

  # Increase rate limit from 60 to 5000
  # You will need Your own client_id & client_secret
  # See: https://github.com/settings/ --> OAuth application
  Octokit.client_id = File.read('/etc/github/client_id').strip
  Octokit.client_secret = File.read('/etc/github/client_secret').strip
  # user = Octokit.user 'some_github_username'
end
