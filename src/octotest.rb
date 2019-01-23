require './ghapi'

gcs = octokit_init
puts "Client initialized, #{gcs.length} keys"
hint = -1
hint, rem, pts = rate_limit(gcs, hint, 2)
begin
  puts 'Next line will cause error that will be handled' if pts <= 0
  puts "2. Suggested client nr #{hint}: #{gcs[hint].user[:login]}, seconds till reset: #{rem}, points: #{pts}"
  hint, rem, pts = rate_limit(gcs, hint, 2)
  puts "3. Suggested client nr #{hint}: #{gcs[hint].user[:login]}, seconds till reset: #{rem}, points: #{pts}"
rescue Octokit::TooManyRequests => e
  puts e
  puts 'Error handled'
end
