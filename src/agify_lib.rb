$g_agify_json_cache_filename = nil

$g_agify_cache = {}
$g_agify_cache_mtx = Concurrent::ReadWriteLock.new

$g_agify_hit = 0
$g_agify_miss = 0
$g_agify_stats_mtx = Concurrent::ReadWriteLock.new

# Thread safe
def get_age(name, login, cid)
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
    $g_agify_cache_mtx.acquire_read_lock
    if $g_agify_cache.key?([name, cid])
      v = $g_agify_cache[[name, cid]]
      $g_agify_cache_mtx.release_read_lock
      while v === false do
        $g_agify_stats_mtx.with_read_lock { v = $g_agify_cache[[name, cid]] }
        # wait until real data become available (not a wip marker)
        sleep 0.001
      end
      $g_agify_stats_mtx.with_write_lock { $g_agify_hit += 1 }
      ret << v
      next
    end
    $g_agify_cache_mtx.release_read_lock
    $g_agify_stats_mtx.with_write_lock { $g_agify_miss += 1 }
    # Write marker that data is computing now: false
    $g_agify_cache_mtx.with_write_lock { $g_agify_cache[[name, cid]] = false }
    suri = "https://api.agify.io?name=#{URI.encode(name)}"
    suri += "&apikey=#{api_key}" if !api_key.nil? && api_key != ''
    suri += "&country_id=#{URI.encode(cid)}" if !cid.nil? && cid != ''
    begin
      uri = URI.parse(suri)
      response = Net::HTTP.get_response(uri)
      data = JSON.parse(response.body)
      # data = { 'name' => 'name' 'age' => 'x', 'count' => 10 }
      # write the final computed data instead of marker: false
      $g_agify_cache_mtx.with_write_lock { $g_agify_cache[[name, cid]] = data }
      ret << data
      if data.key? 'error'
        puts data['error']
        return nil, nil, false
      end
    rescue StandardError => e
      puts e
      return nil, nil, false
    end
  end
  r = ret.reject { |r| r['age'].nil? }.sort_by { |r| [-r['count']] }
  return nil, nil, true if r.count < 1
  return r.first['age'], r.first['count'], true
end
