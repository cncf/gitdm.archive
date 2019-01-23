require './ghapi'

gcs = octokit_init()
puts "Client initialized, #{gcs.length} keys"
hint, rem, pts = rate_limit(gcs, -1, 2)
i = 0
thrs = []
n_thrs = ENV['NCPUS'].nil? ? Etc.nprocessors : ENV['NCPUS'].to_i
loop do
  begin
    thrs << Thread.new do
      begin
        gcs[hint].repo 'cncf/devstats'
      rescue Octokit::AbuseDetected => e
        puts "Abuse detected #{i}, sleep 10 seconds"
        sleep 10
        retry
      end
    end
    while thrs.length >= n_thrs
      dummy =  thrs.first.value
      thrs = thrs[1..-1]
    end
    i += 1
    if i % 100 == 0
      p i
      hint, rem, pts = rate_limit(gcs)
    end
  rescue => e
    puts e
    binding.pry
    break
  end
end
