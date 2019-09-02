$gjson_cache_filename = nil

$gcache = {}
$gcache_mtx = Concurrent::ReadWriteLock.new

$hit = 0
$miss = 0
$gstats_mtx = Concurrent::ReadWriteLock.new

# Thread safe
def get_sex(name, login, cid)
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
    $gcache_mtx.acquire_read_lock
    if $gcache.key?([name, cid])
      v = $gcache[[name, cid]]
      $gcache_mtx.release_read_lock
      while v === false do
        $gstats_mtx.with_read_lock { v = $gcache[[name, cid]] }
        # wait until real data become available (not a wip marker)
        sleep 0.001
      end
      $gstats_mtx.with_write_lock { $hit += 1 }
      ret << v
      next
    end
    $gcache_mtx.release_read_lock
    $gstats_mtx.with_write_lock { $miss += 1 }
    # Write marker that data is computing now: false
    $gcache_mtx.with_write_lock { $gcache[[name, cid]] = false }
    suri = "https://api.genderize.io?name=#{URI.encode(name)}"
    suri += "&apikey=#{api_key}" if !api_key.nil? && api_key != ''
    suri += "&country_id=#{URI.encode(cid)}" if !cid.nil? && cid != ''
    begin
      uri = URI.parse(suri)
      response = Net::HTTP.get_response(uri)
      data = JSON.parse(response.body)
      # data = { 'gender' => 'x', 'probability' => 1.0, 'count' => 10 }
      # write the final computed data instead of marker: false
      $gcache_mtx.with_write_lock { $gcache[[name, cid]] = data }
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
  r = ret.reject { |r| r['gender'].nil? }.sort_by { |r| [-r['probability'], -r['count']] }
  return nil, nil, true if r.count < 1
  return r.first['gender'][0], r.first['probability'], true
end
