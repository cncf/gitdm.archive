require 'pry'
require 'csv'
require 'json'
require './comment'

def gen_aff_files(csv_file)
  # Process affiliations found by Python cncf/gitdm saved in CSV
  # "email","name","company","date_to"
  comps = {}
  emails = {}
  names = {}
  dt_now = DateTime.now.to_date.to_s
  dt_future = DateTime.now.next_year.to_date.to_s
  CSV.foreach(csv_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    c = h['company'].strip
    e = h['email'].strip
    n = h['name'].strip
    d = h['date_to'].strip
    h['date_to'] = d = dt_future if !d || d == ''
    next unless e.include?('@')
    names[n] = {} unless names.key?(n)
    names[n][e] = [] unless names[n].key?(e)
    names[n][e] << h
    emails[e] = [] unless emails.key?(e)
    emails[e] << h
    comps[c] = {} unless comps.key?(c)
    comps[c][n] = {} unless comps[c].key?(n)
    comps[c][n][e] = [] unless comps[c][n].key?(e)
    comps[c][n][e] << h
  end

  wrongs = []
  w = []
  comps.keys.sort.each do |comp_name|
    devs = comps[comp_name]
    devs.keys.sort.each do |dev_name|
      email_list = names[dev_name]
      affs = []
      affse = []
      email_list.keys.sort.each do |email|
        affs << emails[email].map { |a| [a['company'], a['date_to']] }.sort_by { |r| r[1] }.reverse
        affse << emails[email].map { |a| [a['email'], a['company'], a['date_to']] }.sort_by { |r| r[2] }.reverse
      end
      # Very important sanity check
      if affs.uniq.count > 1
        h = {}
        h[dev_name] = affse
        wrongs << JSON.pretty_generate(h)
        w << affse
      end
    end
  end

  if wrongs.count > 0
    puts 'w.select { |r| r.any? { |a| a.length > 1 } }'
    binding.pry
  end
end

if ARGV.size < 1
  puts "Missing argument: CSV_file (all_affs.csv)"
  exit(1)
end

gen_aff_files(ARGV[0])
