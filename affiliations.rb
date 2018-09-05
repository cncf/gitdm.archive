require 'pry'
require 'csv'
require './comment'
require './email_code'

def affiliations(affiliations_file)
  CSV.foreach(affiliations_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    possible_emails = (h['new emails'] || '').split(',').map(&:strip) << h['email'].strip
    emails = ((h['new emails'] || '').split(',').map(&:strip).map { |e| email_encode(e) } << email_encode(h['email'].strip)).reject { |e| e.nil? || e.empty? || !e.include?('!') }.uniq
    if emails.length != possible_emails.length
      puts "Wrong config"
      p h
      binding.pry
    end
  end
end

if ARGV.size < 1
  puts "Missing arguments: affiliations.csv"
  exit(1)
end

affiliations(ARGV[0])
