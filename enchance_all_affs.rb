require 'pry'
require 'json'
require 'csv'
require './comment'
require './email_code'
require './mgetc'

def enchance_all_affs(affs_file, json_file)
  # Process affiliations found by Python cncf/gitdm saved in CSV
  # "email","name","company","date_to","source"
  email_affs = {}
  sources = {}
  CSV.foreach(affs_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    e = email_encode(h['email'].strip)
    c = h['company'].strip
    n = h['name'].strip
    d = h['date_to'].strip
    s = h['source']

    # name --> emails mapping (one name can have multiple emails)
    emails[n] = {} unless emails.key?(n)
    emails[n][e] = true

    # affiliations by email
    email_affs[e] = [] unless email_affs.key?(e)
    if d && d.length > 0
      email_affs[e] << "#{c} < #{d}"
    else
      email_affs[e] << c
    end

    sources[e] = s
  end
  binding.pry
end

if ARGV.size < 2
  puts "Missing arguments: affs_file json_file (all_affs.csv github_users.json)"
  exit(1)
end

enchance_all_affs(ARGV[0], ARGV[1])
