require 'pry'
require 'csv'
require './comment'
require './email_code'
require './mgetc'

def merge_csvs(main_csv, merge_csv, output_csv)
  dbg = !ENV['DBG'].nil?
  ans = ENV['ANS']

  mains = {}
  CSV.foreach(main_csv, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    e = h['email']
    g = h['github']
    k = [e, g]
    mains[k] = h
  end

  merged = {}
  ln = 1
  CSV.foreach(merge_csv, headers: true) do |row|
    ln += 1
    next if is_comment row
    h = row.to_h
    e = h['email']
    g = h['github']
    k = [e, g]
    if mains.key?(k)
      puts "Collision on #{k}, line #{ln}" if dbg
      m = mains[k]
      mg = m['gender']
      ng = h['gender']
      mg = mg.downcase unless mg.nil?
      ng = ng.downcase unless ng.nil?
      ma = m['affiliations']
      na = h['affiliations']
      if mg != ng
        puts "#{k}: Main gender '#{mg}' different than new '#{ng}', line #{ln}" if dbg
        h['gender'] = ng unless ng.nil? or ng == ''
      end
      if ma != na
        puts "#{k}: Main affiliations '#{ma}' different than new '#{na}', line #{ln}" if dbg
        if (ma == '' || ma == '?' || ma.nil?) && na != '' && na != '?' && !na.nil?
          h['affiliations'] = na
        else
          puts "#{k}: Main affiliations '#{ma}' different than new '#{na}', line #{ln}\nUse main or new m/n?"
          if ans.nil?
            a = mgetc.downcase
          else
            a = ans
            puts "Using main '#{ma}'" if a == 'm'
            puts "Using new '#{na}'" if a == 'n'
          end
          h['affiliations'] = ma if a == 'm'
          h['affiliations'] = na if a == 'n'
        end
      end
      h['patches'] = m['patches']
      h['type'] = m['type']
      h['name'] = m['name']
      h['linkedin1'] = m['linkedin1']
      h['linkedin2'] = m['linkedin2']
      h['linkedin3'] = m['linkedin3']
      merged[k] = h
    else
      merged[k] = h
    end
  end
  mains.each do |k, v|
    unless merged.key?(k)
      merged[k] = v
      merged[k]['new emails'] = nil
    end
  end
  ary = merged.values.sort_by { |row| -row['patches'].to_i }
  hdr = merged.values.first.keys
  CSV.open(output_csv, 'w', headers: hdr) do |csv|
    csv << hdr
    ary.each { |item| csv << item.values }
  end
end

if ARGV.size < 3
  puts "Missing arguments: unknowns.csv affiliations.csv merged.csv"
  exit(1)
end

merge_csvs(ARGV[0], ARGV[1], ARGV[2])
