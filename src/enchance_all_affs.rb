require 'pry'
require 'json'
require 'csv'
require './comment'
require './email_code'
require './mgetc'

def mismatch(ary1, ary2)
  s1 = ary1.map(&:strip).sort.join(', ')
  s2 = ary2.map(&:strip).sort.join(', ')
  s1 != s2
end

def enchance_all_affs(affs_file, json_file, old_affs_file)
  # dbg: set to true to have very verbose output
  # silent: set to skip almost all output 
  dbg = !ENV['DBG'].nil?
  silent = !ENV['SILENT'].nil?

  # Process affiliations found by Python cncf/gitdm saved in CSV
  # "email","name","company","date_to","source"
  # Get rid of invalid UTF-8 chars
  contents = File.read(affs_file).scrub
  File.write(affs_file, contents)
  contents = File.read(old_affs_file).scrub
  File.write(old_affs_file, contents)

  # Parse affiliations file
  ln = 1
  email_affs = {}
  email_data = {}
  begin
    CSV.foreach(affs_file, headers: true) do |row|
      next if is_comment row
      h = row.to_h
      e = email_encode(h['email'].strip)
      c = h['company'].strip
      n = h['name'].strip
      d = h['date_to'].strip
      s = (h['source'] || '').strip

      email_affs[e] = [] unless email_affs.key?(e)
      if d && d.length > 0
        email_affs[e] << "#{c} < #{d}"
      else
        email_affs[e] << c
      end

      # needed to add new rows
      email_data[[e, c, d]] = [n, s]

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

  # Parse old affs file
  # email,name,company,date_to,source
  oln = 1
  old_email_data = {}
  begin
    CSV.foreach(old_affs_file, headers: true) do |row|
      next if is_comment row
      h = row.to_h
      e = email_encode(h['email'].strip)
      n = h['name'].strip
      c = h['company'].strip
      d = h['date_to'].strip
      s = (h['source'] || '').strip

      # needed to add new rows
      old_email_data[[e, c, d]] = [n, s]

      oln += 1
    end
  rescue => e
    puts "CSV error on line #{oln}: #{e}"
    binding.pry
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
  conflict = 0
  email_affs.each do |email, affs|
    next if ['NotFound', '(Unknown)'].include?(affs.first)
    unless logins.key?(email)
      puts "JSON have no email '#{email}', skipping" if dbg && !silent
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
      unless email_affs.key?(em)
        new_affs[em] = [email, affs]
        next
      end
      oaffs = email_affs[em]
      if mismatch(affs, oaffs)
        puts "Login '#{l}', original email '#{email}', other email '#{em}' all: #{ems}\nAffiliations mismatch: '#{affs}' != '#{oaffs}'" unless silent
        conflict += 1
      end
    end
  end
  puts "Conflicts: #{conflict}"
  csv_data = []
  new_affs.each do |em, affs_data|
    email = affs_data[0]
    affs = affs_data[1]
    affs.each do |aff_data|
      ary = aff_data.split(' < ')
      c = d = ''
      if ary.length == 1
        c = ary[0]
      else
        c = ary[0]
        d = ary[1]
      end
      unless email_data.key?([email, c, d])
        puts "This is bad: email '#{email}' should have a key for company '#{c}' and date_to '#{d}' while processing new email '#{em}'"
        next
      end
      ary = email_data[[email, c, d]]
      n = ary[0]
      s = ary[1]
      # "email","name","company","date_to","source"
      csv_data << [em, n, c, d, s]
    end
  end

  # Now check old affs CSV: all-affs.old
  old_email_data.each do |ecd, ns|
    e, c, d = ecd
    next if ['NotFound', '(Unknown)'].include?(c)
    n, s = ns
    unless email_affs.key?(e) || new_affs.key?(e)
      if logins.key?(e)
        ems = emails[logins[e]]
        ems.each do |em|
          next if em == e
          p [c, e, em, new_affs[e], new_affs[em], email_affs[e], email_affs[em]]
        end
      end
      csv_data << [e, n, c, d, s]
    end
  end

  fn = 'new_affs.csv'
  hdr = %w(email name company date_to source)
  CSV.open(fn, 'w', headers: hdr, force_quotes: true) do |csv|
    csv << hdr
    csv_data.each { |row| csv << row }
  end
  puts "#{new_affs.length}/#{csv_data.length} new affiliations written to #{fn}, you can append them to #{affs_file}"
end

if ARGV.size < 3
    puts "Missing arguments: affs_file json_file all_affs.old (all_affs.csv github_users.json all_affs.old)"
  exit(1)
end

enchance_all_affs(ARGV[0], ARGV[1], ARGV[2])
