require 'thwait'

task = Thread.new { Thread.stop }
tw = ThreadsWait.new([task])
begin
  t = tw.next_wait
  p t.value
rescue Exception => e
  puts e
end

puts 'survived'
