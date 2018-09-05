require 'pry'
require 'csv'
require './comment'
require './email_code'

def affiliations(affiliations_file)
  all_affs = []
  CSV.foreach(affiliations_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    possible_emails = (h['new emails'] || '').split(',').map(&:strip) << h['email'].strip
    emails = ((h['new emails'] || '').split(',').map(&:strip).map { |e| email_encode(e) } << email_encode(h['email'].strip)).reject { |e| e.nil? || e.empty? || !e.include?('!') }.uniq
    if emails.length != possible_emails.length
      puts "Wrong emails config"
      p h
      binding.pry
    end
    possible_affs = (h['affiliations'] || '').split(',').map(&:strip)
    affs = possible_affs.reject { |a| a.nil? || a.empty? }.uniq
    if affs.length != possible_affs.length
      puts "Wrong affiliations config"
      p h
      binding.pry
    end
    affs.each do |aff|
      possible_data = aff.split('<').map(&:strip)
      data = possible_data.reject { |a| a.nil? || a.empty? }.uniq
      if data.length < 1 || data.length > 2 || data.length != possible_data.length
        puts "Wrong affiliation config"
        p data
        p h
        binding.pry
      end
      if data.length == 1
        emails.each { |e| all_affs << "#{e} #{aff}" }
      elsif data.length == 2
        dt = data[1]
        if dt.length != 10
          puts "Wrong date format expected YYYY-MM-DD, got #{dt} (wrong length)"
          p data
          p h
          binding.pry
        end
        begin
          ddt = DateTime.strptime(dt, '%Y-%m-%d')
          sdt = ddt.strftime("%Y-%m-%d")
          com = data[0]
          emails.each { |e| all_affs << "#{e} #{com} < #{sdt}" }
        rescue => err2
          puts "Wrong date format expected YYYY-MM-DD, got #{dt} (invalid date)"
          p data
          p h
          binding.pry
        end
      end
    end
  end
  p all_affs
end

if ARGV.size < 1
  puts "Missing arguments: affiliations.csv"
  exit(1)
end

affiliations(ARGV[0])
