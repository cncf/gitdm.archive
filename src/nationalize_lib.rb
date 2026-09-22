$g_nationalize_json_cache_filename = nil

$g_nationalize_cache = {}
$g_nationalize_cache_mtx = Concurrent::ReadWriteLock.new

$g_nationalize_hit = 0
$g_nationalize_miss = 0
$g_nationalize_stats_mtx = Concurrent::ReadWriteLock.new

# Thread safe
def get_nat(name, login, prob)
  login = login.downcase.strip
  ary = [login]
  unless name.nil?
    name = name.downcase.strip
    ary = name.split(' ').map(&:strip).reject(&:empty?) << login
  end
  alln = []
  ary.each do |name|
    alln << name
    aname = name.to_ascii.downcase
    alln << aname if aname != name
  end
  alln = alln.uniq
  api_key = ENV['API_KEY']
  ret = []
  alln.each do |name|
    name.delete! '"\'[]%_^@$*+={}:|\\`~?/.<>'
    next if name == ''
    $g_nationalize_cache_mtx.acquire_read_lock
    if $g_nationalize_cache.key?(name)
      v = $g_nationalize_cache[name]
      $g_nationalize_cache_mtx.release_read_lock
      while v === false do
        $g_nationalize_stats_mtx.with_read_lock { v = $g_nationalize_cache[name] }
        # wait until real data become available (not a wip marker)
        sleep 0.001
      end
      $g_nationalize_stats_mtx.with_write_lock { $g_nationalize_hit += 1 }
      ret << v
      next
    end
    $g_nationalize_cache_mtx.release_read_lock
    $g_nationalize_stats_mtx.with_write_lock { $g_nationalize_miss += 1 }
    # Write marker that data is computing now: false
    $g_nationalize_cache_mtx.with_write_lock { $g_nationalize_cache[name] = false }
    suri = "https://api.nationalize.io?name=#{URI.encode(name)}"
    suri += "&apikey=#{api_key}" if !api_key.nil? && api_key != ''
    begin
      uri = URI.parse(suri)
      response = Net::HTTP.get_response(uri)
      data = JSON.parse(response.body)
      # data = { 'name' => 'x', 'country' => [{'country_id' => 'PL', 'probability' => 0.94 }, ...]}
      # write the final computed data instead of marker: false
      $g_nationalize_cache_mtx.with_write_lock { $g_nationalize_cache[name] = data }
      if data.key? 'error'
        puts data['error']
        return nil, nil, false
      end
      unless data.key? 'country'
        puts "Missing 'country' key in result"
        p data
        return nil, nil, false
      end
      data['country'].each do |row|
        ret << row if row['probability'] >= prob
      end
    rescue StandardError => e
      puts e
      return nil, nil, false
    end
  end
  r = ret.reject { |r| r['country_id'].nil? }.sort_by { |r| [-r['probability']] }
  return nil, nil, true if r.count < 1
  return r.first['country_id'].downcase, r.first['probability'], true
end
