require 'pry'
require 'etc'
require 'octokit'

# Check all clients rate limit or only check rate limit given by last_hint >= 0
# You can use last_hint when you know that you only used client[last_hint] to avoid checking the remaining ones.
$g_rls = []
def rate_limit(clients, last_hint = -1, debug = 1)
  # This is to force checking other clients state with 1/N probablity.
  # Even if we don't use them, they can reset to a higher API points after <= 1h
  last_hint = -1 if last_hint >= 0 && Time.now.to_i % clients.length == 0
  rls = []
  if $g_rls.length > 0 && last_hint >= 0
    rls = $g_rls
    puts "Checking rate limit for #{clients[last_hint].user[:login]}" if debug >= 2
    rls[last_hint] = clients[last_hint].rate_limit
  else
    thrs = []
    n_thrs = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
    clients.each_with_index do |client, idx|
      thrs << Thread.new do
        puts "Checking rate limit for #{client.user[:login]}" if debug >= 2
        client.rate_limit
      end
      while thrs.length >= n_thrs
        rls << thrs.first.value
        puts "Checked rate limit for #{clients[rls.length-1].user[:login]}" if debug >= 2
        thrs = thrs[1..-1]
      end
    end
    thrs.each_with_index do |thr, idx|
      rls << thr.value
      puts "Checked rate limit for #{clients[idx].user[:login]}" if debug >= 2
    end
  end
  $g_rls = rls
  hint = 0
  rls.each_with_index do |rl, idx|
    if rl.remaining > rls[hint].remaining
      hint = idx
    elsif idx != hint && rl.remaining == rls[hint].remaining && rl.resets_in < rls[hint].resets_in
      hint = idx
    end
  end
  users = clients.map { |client| client.user[:login] }
  limits = rls.map { |rl| rl.limit }
  remainings = rls.map { |rl| rl.remaining }
  resets_ats = rls.map { |rl| rl.resets_at.strftime("%H:%M:%S") }
  resets_ins = rls.map { |rl| "#{rl.resets_in}s" }
  rem = (rls[hint].resets_at - Time.now).to_i + 1
  puts "#{users}: hint: #{hint}, limits=#{limits}, remainings=#{remainings}, resets_ats=#{resets_ats}, resets_ins=#{resets_ins}" if debug >= 1
  puts "Suggested client nr #{hint}: #{clients[hint].user[:login]}, remaining API points: #{remainings[hint]}, resets at #{resets_ats[hint]}, seconds till reset: #{rem}" if debug >= 0
  [hint, rem, remainings[hint]]
end

# Reads comma separated OAuth keys from '/etc/github/oauths' fallback to single OAuth key from '/etc/github/oauth'
# Reads comma separated OAuth application client IDs from '/etc/github/client_ids' fallback to single client ID from '/etc/github/client_id'
# Reads comma separated OAuth application client secrets from '/etc/github/client_secrets' fallback to single client secret from '/etc/github/client_secret'
# If multiple keys, client IDs and client secrets are used then you need to have the same number of entries in all 3 files and in the same order line
# '/etc/github/oauths': key1,key2,key3 (3 different github accounts)
# '/etc/github/client_ids' id1,id2,id3 (the same 3 github accounts in the same order)
# '/etc/github/client_secrets' secret1,secret2,secret3 (the same 3 github accounts in the same order)
def octokit_init()
  # Auto paginate results, this uses maximum page size 100 internally and calls API # of results / 100 times.
  Octokit.auto_paginate = true

  # Login with standard OAuth token
  # https://github.com/settings/tokens --> Personal access tokens
  puts "Processing OAuth data."
  tokens = []
  begin
    data = File.read('/etc/github/oauths').strip
    tokens = data.split(',').map(&:strip)
  rescue Errno::ENOENT => e
    begin
      data = File.read('/etc/github/oauth').strip
    rescue Errno::ENOENT => e
      puts "No OAuth token(s) found"
      exit 1
    end
    tokens = [data]
  end

  # Increase rate limit from 60 to 5000
  # You will need Your own client_id & client_secret
  # See: https://github.com/settings/ --> OAuth application
  client_ids = []
  begin
    data = File.read('/etc/github/client_ids').strip
    client_ids = data.split(',').map(&:strip)
  rescue Errno::ENOENT => e
    begin
      data = File.read('/etc/github/client_id').strip
    rescue Errno::ENOENT => e
      puts "No client ID(s) tokens found"
      exit 1
    end
    client_ids = [data]
  end
  client_secrets = []
  begin
    data = File.read('/etc/github/client_secrets').strip
    client_secrets = data.split(',').map(&:strip)
  rescue Errno::ENOENT => e
    begin
      data = File.read('/etc/github/client_secret').strip
    rescue Errno::ENOENT => e
      puts "No client ID(s) tokens found"
      exit 1
    end
    client_secrets = [data]
  end

  puts "Connecting #{tokens.length} clients."
  # Process tripples, create N threads to handle client creations
  clients = []
  thrs = []
  n_thrs = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
  tokens.each_with_index do |token, idx|
    thrs << Thread.new do
      puts "Connecting client nr #{idx}"
      client = Octokit::Client.new(
        access_token: token,
        client_id: client_ids[idx],
        client_secret: client_secrets[idx]
      )
    end
    while thrs.length >= n_thrs
      client =  thrs.first.value
      clients << client
      thrs = thrs[1..-1]
      puts "Connected #{client.user[:login]}"
    end
  end
  thrs.each do |thr|
    # user = client.user
    # user.login
    client = thr.value
    clients << client
    puts "Connected #{client.user[:login]}"
  end
  clients
end
