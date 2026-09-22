require 'pry'
require 'scanf'
require './mgetc'
require './email_code'

def import_affs(dev_affs, comp_devs)
  # Developers affiliations
  d_affs = []
  emails = []
  d_dict = {}
  File.readlines(dev_affs).each do |line|
    next if line.strip[0..1] == '# '
    data = line.split(': ').map(&:strip)
    data = [data.join(': ')] if data[0] == 'Was'
    if data.length == 2
      emails = data[1].split(', ')
    elsif data.length == 1
      data2 = data.first.split(' until ')
      if data2.length > 2
        puts 'Unexpected line:'
        puts line
        binding.pry
      end
      emails.each do |email|
        email = email_encode(email)
        d_dict[email] = [] unless d_dict.key?(email)
        if data2.length == 1
          d_affs << "#{email} #{data2.first}"
          d_dict[email] << [data2.first, '']
        else
          d_affs << "#{email} #{data2.first} < #{data2.last}"
          d_dict[email] << data2
        end
      end
    else
      puts 'Unexpected line:'
      puts line
      binding.pry
    end
  end
  d_affs = d_affs.sort

  # Company developers
  cname = ''
  c_affs = []
  c_dict = {}
  File.readlines(comp_devs).each do |line|
    next if line.strip[0..1] == '# '
    data = line.split(':')
    data = [data[0..-2].join(':'), data[-1]] if data.length > 2
    data = data.map(&:strip)
    if data.length == 2 
      if data.last == ''
        cname = data.first
      else
        data2 = data.last.split(', ')
        emails = data2.select { |r| r.include?('!') }.map { |r| r.split(' ').first }.map(&:strip)
        dates = data2.select { |r| r.include?('from') || r.include?('until') }.map { |r| r.split(' ') }.flatten.reject { |r| r.include?('!') }.map(&:strip)
        if dates.length % 2 == 1
          puts 'Unexpected line:'
          puts line
          p [emails, dates]
          binding.pry
        end
        dts = []
        n = dates.length
        if n > 0
          has_until = false
          last_from = false
          (0...n/2).each do |i|
            kw = dates[i * 2]
            last_from = kw == 'from'
            next unless kw == 'until'
            has_until = true
            dt = dates[i * 2 + 1]
            dts << dt
          end
          dts << '' if !has_until || last_from
        else
          dts << ''
        end
        emails.each do |email|
          email = email_encode(email)
          c_dict[email] = [] unless c_dict.key?(email)
          dts.each do |dt|
            if dt == ''
              c_affs << "#{email} #{cname}"
              c_dict[email] << [cname, '']
            else
              c_affs << "#{email} #{cname} < #{dt}"
              c_dict[email] << [cname, dt]
            end
          end
        end
      end
    else
      puts 'Unexpected line:'
      puts line
      binding.pry
    end
  end

  c_affs = c_affs.sort
  oos = ((d_dict.keys - c_dict.keys) + (c_dict.keys - d_dict.keys)).uniq.sort
  oos.each do |key|
    unless d_dict.key?(key)
      puts "Developers affiliations does not contain `#{key}`, while company developers data is:"
      p c_dict[key]
    end
    unless c_dict.key?(key)
      puts "Company developers does not contain `#{key}`, while developer affiliations data is:"
      p d_dict[key]
    end
  end

  diffs = []
  skip = false
  d_dict.keys.each do |key|
    next unless c_dict.key?(key)
    unless c_dict[key].sort == d_dict[key].sort
      puts "Oops: #{key}"
      puts "company_developers.txt:"
      p c_dict[key].sort
      puts "developers_affiliations.txt:"
      p d_dict[key].sort
      diffs << [key, c_dict[key], d_dict[key]]
      unless skip
        puts "Want to stop in debugger? (y/n/q)"
        c = mgetc
        skip = true if c == 'q'
        binding.pry if c == 'y'
      end
    end
  end

  dfs = d_affs
  unless diffs.length == 0
    puts 'We are out of sync, check `diffs`, `c_dict`, `d_dict`'
    puts "You can save new config file giving priority to:"
    puts "d: developer_affiliations.txt (current)"
    puts "c: company_developers.txt"
    puts "q: do not save output"
    puts "b: stop in the debuger"
    puts "Your choice? (d/c/q/b)"
    c = mgetc
    dfs = c_affs if c == 'c'
    dfs = nil if c == 'q'
    if c == 'b'
      puts "Set `dfs` variable to d_affs or c_affs or nil"
      binding.pry
    end
  end

  return unless dfs
  hdr = [
    '# Here is a set of mappings of domain names onto employer names.',
    '# [user!]domain  employer  [< yyyy-mm-dd]'
  ]
  File.write 'email-map', (hdr + dfs).join("\n")
  puts 'Generated email-map file, consider using it as a cncfdm.py config file `cncf-config/email-map`'
  if diffs.length > 0
    puts 'Please follow instructions from SYNC.md'
  end
end

if ARGV.size < 2
  puts "Missing arguments: developers_affiliations.txt company_developers.txt"
  exit(1)
end

import_affs(ARGV[0], ARGV[1])
