require './ghapi'

gcs = octokit_init()
puts "Client initialized, #{gcs.length} keys"
hint, rem, pts = rate_limit(gcs)
puts "2. Suggested client nr #{hint}: #{gcs[hint].user[:login]}, seconds till reset: #{rem}, points: #{pts}"
hint, rem, pts = rate_limit(gcs, hint)
puts "3. Suggested client nr #{hint}: #{gcs[hint].user[:login]}, seconds till reset: #{rem}, points: #{pts}"
