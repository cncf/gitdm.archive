#!/usr/bin/env ruby

require 'csv'
require 'pry'
require 'octokit'
require 'json'
require 'concurrent'
require 'unidecoder'
require 'pg'

require './email_code'
require './ghapi'
require './genderize_lib'
require './geousers_lib'
require './nationalize_lib'
require './agify_lib'

def genderize_get_gcache
  ary = []
  $g_genderize_cache_mtx.with_read_lock { $g_genderize_cache.each { |key, val| ary << [key, val] unless val === false } }
  ary
end

def geousers_get_gcache
  ary = []
  $g_geousers_cache_mtx.with_read_lock { $g_geousers_cache.each { |key, val| ary << [key, val] unless val === false } }
  ary
end

def nationalize_get_gcache
  ary = []
  $g_nationalize_cache_mtx.with_read_lock { $g_nationalize_cache.each { |key, val| ary << [key, val] unless val === false } }
  ary
end

def agify_get_gcache
  ary = []
  $g_agify_cache_mtx.with_read_lock { $g_agify_cache.each { |key, val| ary << [key, val] unless val === false } }
  ary
end

if ARGV.length < 1
  # wget https://teststats.cncf.io/backups/prestodb_unknown_committers.csv
  puts "You need to specify CSV file to work [unknown_committers.csv]"
  exit 1
end

skipcache = !ENV['SKIP_CACHE'].nil?
skipenc = !ENV['SKIP_ENC'].nil?
skipgdpr = !ENV['SKIP_GDPR'].nil?
unless skipcache || skipenc

  $g_geousers_json_cache_filename = 'geousers_cache.json'
  cache = JSON.parse File.read $g_geousers_json_cache_filename
  cache.each { |key, val| $g_geousers_cache[key] = val unless val === false }

  if skipgdpr
    $g_genderize_json_cache_filename = 'genderize_cache.json'
    cache = JSON.parse File.read $g_genderize_json_cache_filename
    cache.each { |key, val| $g_genderize_cache[key] = val unless val === false }

    $g_nationalize_json_cache_filename = 'nationalize_cache.json'
    cache = JSON.parse File.read $g_nationalize_json_cache_filename
    cache.each { |key, val| $g_nationalize_cache[key] = val unless val === false }

    $g_agify_json_cache_filename = 'agify_cache.json'
    cache = JSON.parse File.read $g_agify_json_cache_filename
    cache.each { |key, val| $g_agify_cache[key] = val unless val === false }
  end

  Signal.trap('INT') do
    puts "Caught signal, saving cache and exiting"

    pretty = JSON.pretty_generate geousers_get_gcache
    File.write $g_geousers_json_cache_filename, pretty

    if skipgdpr
      pretty = JSON.pretty_generate genderize_get_gcache
      File.write $g_genderize_json_cache_filename, pretty

      pretty = JSON.pretty_generate nationalize_get_gcache
      File.write $g_nationalize_json_cache_filename, pretty

      pretty = JSON.pretty_generate agify_get_gcache
      File.write $g_agify_json_cache_filename, pretty
    end

    puts "Saved"
    exit 1
  end
end

# type,email,name,github,linkedin1,linkedin2,linkedin3,commits,gender,location,affiliations,new emails
prob = 0.5
unless ENV['PROB'].nil?
  prob = ENV['PROB'].to_f
end
freq = 1000
unless ENV['FREQ'].nil?
  freq = ENV['FREQ'].to_f
end
keyw = !ENV['KEYW'].nil?
gcs = octokit_init()
hint = rate_limit(gcs)[0]
init_sqls()

skipcopy = !ENV['SKIP_COPY'].nil?
affs = {}
unless skipcopy
  CSV.foreach('affiliations.csv', headers: true) do |row|
    gh = row['github']
    actor = gh[19..-1]
    a = row['affiliations']
    affs[actor] = a unless [nil, '', 'NotFound', '(Unknown)', '?'].include?(a)
  end
end

json = JSON.parse(File.read('github_users.json'))
data = {}
ks = {}
ghaffs = {}
json.each do |row|
  login = row['login'].downcase
  email = row['email'].downcase
  row.keys.each { |k| ks[k] = 0 }
  data[login] = {} unless data.key?(login)
  data[login][email] = row
  aff = row['affiliation']
  ghaffs[login] = aff unless [nil, '', 'NotFound', '(Unknown)', '?'].include?(aff)
end

ary = []
new_objs = []
commits = {}
idx = 0
CSV.foreach(ARGV[0], headers: true) do |row|
  #rank_number,actor,commits,percent,cumulative_sum,cumulative_percent,all_commits
  #rank_number,actor,contributions,percent,cumulative_sum,cumulative_percent,all_contributions
  #rank_number,actor,events,percent,cumulative_sum,cumulative_percent,all_events
  idx += 1
  ghid = row['actor']
  next if ghid == nil
  lghid = ghid.downcase
  commits[ghid] = row['commits'] || row['contributions'] || row['events']
  email = "#{ghid}!users.noreply.github.com"
  lemail = email.downcase
  emails = []
  if data.key?(lghid)
    data[lghid].keys.each do |em|
      lem = em.downcase
      if lem != lemail
        emails << em
      end
    end
    emails = [email] if emails.length == 0
    if data[lghid].key?(lemail)
      puts "Exact match #{lghid}/#{lemail}"
      obj = data[lghid][lemail].dup
      if affs.key?(ghid)
        obj['affiliation'] = affs[ghid]
      else
        obj['affiliation'] = ''
      end
      obj['emails'] = emails
      puts "Emails #{obj['emails']}"
      ary << obj
    else
      puts "Partial match: #{lghid}"
      obj = data[lghid][data[lghid].keys[0]].dup
      obj['email'] = email
      # obj['commits'] = commits[ghid]
      obj['commits'] = 0
      new_objs << obj
      obj2 = obj.dup
      if affs.key?(ghid)
        obj2['affiliation'] = affs[ghid]
      else
        obj2['affiliation'] = ''
      end
      obj2['emails'] = emails
      puts "Emails #{obj2['emails']}"
      ary << obj2
    end
  else
    puts "#{idx}) Asking GitHub for #{ghid}"
    begin
      u = gcs[hint].user ghid
    rescue Octokit::NotFound => err
      puts "GitHub doesn't know actor #{ghid}"
      puts err
      next
    rescue Octokit::AbuseDetected => err
      puts "Abuse #{err} for #{ghid}, sleeping 30 seconds"
      sleep 30
      retry
    rescue Octokit::TooManyRequests => err
      hint, td = rate_limit(gcs)
      puts "Too many GitHub requests for #{ghid}, sleeping for #{td} seconds"
      if td > 0
        sleep td
      else
        puts "sleep request for <= 0 seconds (#{td}), sleeping 10s instead"
        sleep 10
      end
      retry
    rescue Zlib::BufError, Zlib::DataError, Faraday::ConnectionFailed => err
      puts "Retryable error #{err} for #{ghid}, sleeping 10 seconds"
      sleep 10
      retry
    rescue => err
      puts "Uups, something bad happened for #{ghid}, check `err` variable!"
      STDERR.puts [err.class, err]
      binding.pry
      next
    end
    h = u.to_h
    unless skipenc
      if skipgdpr
        if h[:location]
          print "Geolocation for #{h[:location]} "
          h[:country_id], h[:tz], ok = get_cid h[:location]
          puts "-> (#{h[:country_id]}, #{h[:tz]}, #{ok})"
        else
          h[:country_id], h[:tz] = nil, nil
        end
        if h[:country_id].nil? || h[:tz].nil? || h[:country_id] == '' || h[:tz] == ''
          print "Nationalize: (#{h[:login]}, #{h[:name]}) -> "
          cid, prb, ok = get_nat h[:name], h[:login], prob
          tz, ok2 = get_tz cid unless cid.nil?
          print "(#{cid}, #{tz}, #{prb}, #{ok}, #{ok2}) -> "
          h[:country_id] = cid if h[:country_id].nil?
          h[:tz] = tz if h[:tz].nil?
          puts "(#{h[:country_id]}, #{h[:tz]})"
        end
        print "Genderize: (#{h[:name]}, #{h[:login]}, #{h[:country_id]}) "
        h[:sex], h[:sex_prob], ok = get_sex h[:name], h[:login], h[:country_id]
        puts "-> (#{h[:sex]}, #{h[:sex_prob]}, #{ok})"
        print "Agify: (#{h[:login]}, #{h[:name]}, #{h[:country_id]}) "
        h[:age], cnt, ok = get_age h[:name], h[:login], h[:country_id]
        puts "(#{h[:age]}, #{cnt}, #{ok})"
      else
        if h[:location]
          print "Geolocation for #{h[:location]} "
          h[:country_id], stub, ok = get_cid h[:location]
          puts "-> (#{h[:country_id]}, #{stub}, #{ok})"
        else
          h[:country_id] = nil
        end
      end
    else
      h[:country_id], h[:tz] = nil, nil
      h[:sex], h[:sex_prob] = nil, nil
      h[:age] = nil
    end
    h[:commits] = 0
    if affs.key?(ghid)
      h[:affiliation] = affs[ghid]
    else
      h[:affiliation] = ''
    end
    h[:email] = "#{ghid}!users.noreply.github.com" if !h.key?(:email) || h[:email].nil? || h[:email] == ''
    h[:email] = email_encode(h[:email])
    h[:source] = "config"
    obj = {}
    ks.keys.each { |k| obj[k.to_s] = h[k.to_sym] }
    obj['emails'] = [obj['email']] if !obj.key?('emails') || obj['emails'].nil?
    puts "Emails #{obj['emails']}"
    new_objs << obj
    ary << obj
  end
  if !skipcache && (idx > 0 && idx % freq == 0)
    puts 'Writting caches...'
    pretty = JSON.pretty_generate geousers_get_gcache
    File.write $g_geousers_json_cache_filename, pretty

    if skipgdpr
      pretty = JSON.pretty_generate genderize_get_gcache
      File.write $g_genderize_json_cache_filename, pretty

      pretty = JSON.pretty_generate nationalize_get_gcache
      File.write $g_nationalize_json_cache_filename, pretty

      pretty = JSON.pretty_generate agify_get_gcache
      File.write $g_agify_json_cache_filename, pretty
    end
  end
end

linkedin_base = 'https://www.linkedin.com/search/results/all/?origin=GLOBAL_SEARCH_HEADER&keywords='
puts "Writting CSV..."
hdr = %w(type email name github linkedin1 linkedin2 linkedin3 commits gender location affiliations)
hdr << 'new emails'
CSV.open('task.csv', 'w', headers: hdr) do |csv|
  csv << hdr
  ary.each do |row|
    login = row['login']
    binding.pry if row['emails'].nil?
    email = row['emails'].join(', ')
    email = "#{login}!users.noreply.github.com" if email.nil?
    name = row['name'] || ''
    emails = row['emails']
    ary2 = emails[0].split '!'
    uname = ary2[0]
    dom = ary2[1]
    escaped_name = URI.escape(name)
    escaped_uname = URI.escape(name + ' ' + uname)
    lin1 = lin2 = lin3 = ''
    gh = "https://github.com/#{login}"
    aff = row['affiliation']
    if [nil, '', 'NotFound', '(Unknown)', '?'].include?(aff) && ghaffs.key?(login)
      aff = ghaffs[login]
      puts "Using JSON: '#{aff}' affiliation for '#{login}/#{email}'"
    end
    if !dom.nil? && dom.length > 0 && dom != 'users.noreply.github.com'
      ary3 = dom.split '.'
      domain = ary3[0]
      escaped_domain = URI.escape(name + ' ' + domain)
      if keyw
        lin1 = name + ' ' + uname
        lin2 = name + ' ' + domain
        lin3 = name + ' ' + login
      else
        lin1 = linkedin_base + escaped_name
        lin2 = linkedin_base + escaped_uname
        lin3 = linkedin_base + escaped_domain
      end
    else
      if keyw
        lin1 = name + ' ' + uname
        lin2 = name + ' ' + login
        lin3 = uname + ' ' + login
      else
        lin1 = linkedin_base + escaped_name
        lin2 = linkedin_base + escaped_uname
      end
    end
    loc = ''
    loc += row['location'] unless row['location'].nil?
    if loc != ''
      loc += '/' + row['country_id'] unless row['country_id'].nil?
    else
      loc += row['country_id'] unless row['country_id'].nil?
    end
    csv << ['(Unknown)', email, name, gh, lin1, lin2, lin3, commits[login], row['sex'], loc, aff, '']
  end
end

puts "Writting JSON..."
new_objs.each do |row|
  row.delete('emails')
  json << row
end
json_data = email_encode(JSON.pretty_generate(json))
File.write 'github_users.json', json_data

unless skipcache
  puts 'Writting caches...'
  pretty = JSON.pretty_generate geousers_get_gcache
  File.write $g_geousers_json_cache_filename, pretty

  if skipgdpr
    pretty = JSON.pretty_generate genderize_get_gcache
    File.write $g_genderize_json_cache_filename, pretty

    pretty = JSON.pretty_generate nationalize_get_gcache
    File.write $g_nationalize_json_cache_filename, pretty

    pretty = JSON.pretty_generate agify_get_gcache
    File.write $g_agify_json_cache_filename, pretty
  end
end
