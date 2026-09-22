require 'pry'
require 'json'
require 'csv'
require './comment'
require './email_code'

def progress_report(json_file, csv_file)
  # Config report
  min_committers = 1
  max_committers = 25
  skip_mult = true
  check_all = false

  # Only check emails that are actually used by gitdm.
  # "email","company","date_to"
  all_emails = {}
  CSV.foreach(csv_file, headers: true) do |row|
    next if is_comment row
    h = row.to_h
    e = email_encode(h['email'].strip)
    all_emails[e] = true
  end

  # Parse JSON
  data = JSON.parse File.read json_file
  vals = {}
  all = 0.0
  data.each do |user|
    c = user['affiliation'].strip
    next if ['?'].include?(c)
    e = email_encode(user['email'].strip)
    next if check_all && !all_emails.key?(e)
    n = user['commits'].to_i
    vals[n] = { n: 0.0 } unless vals.key?(n)
    vals[n][:n] += 1.0
    vals[n][c] = { n: 0.0 } unless vals[n].key?(c)
    vals[n][c][:n] += 1.0
    all += 1.0
  end
  n_commits_numbers = vals.keys.count

  vals.each do |n, comps|
    comps[:percent] = (100.0 * (comps[:n] / all)).round(2)
    comps.each do |key, company|
      next if key.is_a?(Symbol)
      company[:percent] = (100.0 * (company[:n] / comps[:n])).round(2)
    end
  end

  all_specials = [
    ['(Unknown)'],
    ['NotFound'],
    ['Independent'],
    ['(Unknown)', 'NotFound'],
    ['(Unknown)', 'NotFound', 'Independent']
  ]
  all_specials.each do |specials|
    puts ''
    puts '=============================================='
    puts specials
    puts '=============================================='
    puts ''

    vals.keys.sort.reverse.each do |n|
      comps = vals[n]
      if comps.keys.count == 3
        only = comps.keys.select { |k| k.is_a?(String) }.first
        if specials.include?(only)
          puts "There are #{'%-5s' % comps[:n].to_i} committer(s) in #{'%-8s' % only} company with #{'%-5d' % n} commit(s) (#{'%-5.2f' % comps[:percent]}%)"
        end
        next
      end

      hdr_displayed = false
      hdr = "There are #{'%-5s' % comps[:n].to_i} committer(s) with #{'%-5d' % n} commit(s) (#{'%-5.2f' % comps[:percent]}%):"
      comps.keys.reject { |k| k.is_a?(Symbol) }.map { |k| [k, comps[k][:n].to_i, comps[k][:percent]] }.sort_by { |r| -r[1] }.each do |row|
        c = row[0]
        next unless specials.include?(c)
        puts hdr unless hdr_displayed
        hdr_displayed = true
        puts "#{'%-8s' % (row[0] + ':')} #{'%-5d' % row[1]} commit(s) (#{'%-5.2f' % row[2]}%)"
      end
    end
  end

  puts ''
  puts ''
  puts '=============================================='
  puts 'All companies report'
  puts '=============================================='
  puts ''
  puts ''
  vals.keys.sort.reverse.each do |n|
    comps = vals[n]
    next if n < min_committers || n > max_committers
    if comps.keys.count == 3
      only = comps.keys.select { |k| k.is_a?(String) }.first
      puts "There are #{'%-5s' % comps[:n].to_i} committer(s) in #{'%-30s' % only} company with #{'%-5d' % n} commit(s) (#{'%-5.2f' % comps[:percent]}%)"
      next
    end
    puts "There are #{'%-5s' % comps[:n].to_i} committer(s) with #{'%-5d' % n} commit(s) (#{'%-5.2f' % comps[:percent]}%):"
    comps.keys.reject { |k| k.is_a?(Symbol) }.map { |k| [k, comps[k][:n].to_i, comps[k][:percent]] }.sort_by { |r| -r[1] }.each do |row|
      c = row[0]
      next if skip_mult && c.include?('<')
      puts "#{'%-30s' % (row[0] + ':')} #{'%-5d' % row[1]} commit(s) (#{'%-5.2f' % row[2]}%)"
    end
    puts ''
  end
end

if ARGV.size < 2
  puts "Missing arguments: JSON_file CSV_file (github_users.json all_affs.csv)"
  exit(1)
end

progress_report(ARGV[0], ARGV[1])
