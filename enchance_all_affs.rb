require 'pry'
require 'json'
require 'csv'
require './comment'
require './email_code'
require './mgetc'

def enchance_all_affs(affs_file, json_file)
  # dbg: set to true to have very verbose output
  dbg = !ENV['DBG'].nil?

  # Process affiliations found by Python cncf/gitdm saved in CSV
  # "email","name","company","date_to","source"
  # Get rid of invalid UTF-8 chars
  contents = File.read(affs_file).scrub
  File.write(affs_file, contents)

  # Parse affiliations file
  ln = 1
  email_affs = {}
  sources = {}
  begin
    CSV.foreach(affs_file, headers: true) do |row|
      next if is_comment row
      h = row.to_h
      e = email_encode(h['email'].strip)
      c = h['company'].strip
      n = h['name'].strip
      d = h['date_to'].strip
      s = h['source']

      email_affs[e] = [] unless email_affs.key?(e)
      if d && d.length > 0
        email_affs[e] << "#{c} < #{d}"
      else
        email_affs[e] << c
      end

      sources[e] = s
      ln += 1
    end
  rescue => e
    puts "CSV error on line #{ln}: #{e}"
    binding.pry
  end
  email_affs.each do |email, affs|
    saffs = affs.join(', ')
    suaffs = affs.uniq.join(', ')
    if saffs != suaffs
      puts "Warning: email '#{email}' has non-unique affiliations: #{affs}: '#{saffs}' != '#{suaffs}'"
    end
  end

  # Parse JSON (only login emails connections)
  data = JSON.parse File.read json_file
  emails = {}
  logins = {}
  data.each_with_index do |user, idx|
    e = email_encode(user['email'])
    l = user['login'].strip
    logins[e] = l
    emails[l] = [] unless emails.key?(l)
    emails[l] << e
  end

  # Check if we have all emails from JSON in our CSV
  new_affs = {}
  email_affs.each do |email, affs|
      next if ['NotFound', '(Unknown)'].include?(affs.first)
    unless logins.key?(email)
      puts "JSON have no email '#{email}', skipping" if dbg
      next
    end
    l = logins[email]
    ems = emails[l]
    if ems.length < 1
      puts "Login for email '#{email}' found: '#{l}', but reverse map of emails empty"
      next
    end
    ems.each do |em|
      next if em == email
      new_affs[em] = affs unless email_affs.key?(em)
    end
  end

  binding.pry
end

if ARGV.size < 2
  puts "Missing arguments: affs_file json_file (all_affs.csv github_users.json)"
  exit(1)
end

enchance_all_affs(ARGV[0], ARGV[1])
