#!/usr/bin/env ruby

require 'csv'
require 'pry'

require './email_code'

$g_all_affs = {}

def process_affiliation(uname, name, emails, companies)
  # type,email,name,github,linkedin1,linkedin2,linkedin3,commits,gender,location,affiliations,new emails
    ['(Unknown)', emails.sort.uniq.join(', '), uname, "https://github.com/#{name}", '', '', '', '0', '', '', companies.join(','), '']
end

def process_unknown(uname, name, emails, companies)
  # rank_number,actor,commits,percent,cumulative_sum,cumulative_percent,all_commits
  ['0', name, '0', '0','0', '0', '0']
end

def process_new(uname, name, emails, companies)
  # email,name,company,date_to,source
  rows = []
  emails.each do |email|
    lemail = email.strip.downcase
    if $g_all_affs.key?(lemail)
      companies.each do |company_data|
        ary = company_data.split('<')
        date_to = ''
        company = ''
        if ary.length == 1
          company = ary[0].strip
        elsif ary.length == 2
          company = ary[0].strip
          date_to = ary[1].strip
        else
          puts "Wrong company data: #{company_data}"
          p [uname, name, emails, companies]
          binding.pry
          next
        end
        lcompany = company.downcase
        if $g_all_affs[lemail].key?(lcompany)
          ldate = date_to.downcase
          ldate2 = $g_all_affs[lemail][lcompany]
          if ldate != ldate2
            puts "Conflict for #{lemail} #{lcompany}: #{ldate} != #{ldate2}"
            p [uname, name, emails, companies]
            binding.pry
            next
          end
        else
          puts "New company found: #{lcompany}"
          binding.pry
          # Here we probably need to add a new company, but manual check is required
          # There should be exactly one final company for example
        end
        # rows << [email, uname, company, date_to, 'user']
      end
      next
    end
    companies.each do |company_data|
      ary = company_data.split('<')
      date_to = ''
      company = ''
      if ary.length == 1
        company = ary[0].strip
      elsif ary.length == 2
        company = ary[0].strip
        date_to = ary[1].strip
      else
        puts "Wrong company data: #{company_data}"
        p [uname, name, emails, companies]
        binding.pry
        next
      end
      rows << [email, uname, company, date_to, 'user']
    end
  end
  rows
end

def pr_data_to_csv(pr_data_file, affs_csv_file, unkn_csv_file, all_affs_file, new_affs_file)
  CSV.foreach(all_affs_file, headers: true) do |row|
    h = row.to_h
    e = email_encode(h['email'].strip.downcase)
    c = h['company'].strip.downcase
    d = h['date_to'].strip.downcase
    $g_all_affs[e] = {} unless $g_all_affs.key?(e)
    $g_all_affs[e][c] = d
  end
  companies = []
  emails = []
  name = ''
  uname = ''
  n = 0
  data = []
  unkn = []
  new_affs = []
  File.readlines(pr_data_file).each do |line|
    n += 1
    line = email_encode(line.delete(" \t\r\n"))
    ary = line.split(':')
    if ary.length == 2
      if companies.length > 0
        data << process_affiliation(uname, name, emails, companies)
        unkn << process_unknown(uname, name, emails, companies)
        process_new(uname, name, emails, companies).each { |row| new_affs << row }
      end
      companies = []
      name = ary[0]
      uname = name
      emails = ary[1].split(',')
      emails.each do |email|
        ary2 = email.split('!')
        if ary2.length != 2
          puts "Invalid email '#{email}' in line #{n}: #{line}"
          binding.pry
          next
        end
        domain = ary2[1]
        if domain == 'users.noreply.github.com'
          ename = ary2[0]
          if ename != name
            puts "Using github username from email '#{ename}' instead of '#{name}'"
            name = ename
          end
        end
      end
    elsif ary.length == 1
      aff = ary[0]
      ary2 = aff.split('<')
      if ary2.length > 2
        puts "Invalid affiliation config (more than one <), line #{n}: #{line}"
        binding.pry
        next
      end
      ary2 = aff.split(',')
      if ary2.length > 1
        puts "Invalid affiliation config (contains ,), line #{n}: #{line}"
        binding.pry
        next
      end
      companies << aff
    else
      puts "Invalid line, more than one : found, line  #{n}: #{line}"
      binding.pry
      next
    end
  end
  if companies.length > 0
    data << process_affiliation(uname, name, emails, companies)
    unkn << process_unknown(uname, name, emails, companies)
    process_new(uname, name, emails, companies).each { |row| new_affs << row }
  end
  puts "Writting #{affs_csv_file}..."
  hdr = %w(type email name github linkedin1 linkedin2 linkedin3 commits gender location affiliations)
  hdr << 'new emails'
  CSV.open(affs_csv_file, 'w', headers: hdr) do |csv|
    csv << hdr
    data.each { |row| csv << row }
  end
  puts "Writting #{unkn_csv_file}..."
  hdr = %w(rank_number actor commits percent cumulative_sum cumulative_percent all_commits)
  CSV.open(unkn_csv_file, 'w', headers: hdr) do |csv|
    csv << hdr
    unkn.each { |row| csv << row }
  end
  puts "Writting #{new_affs_file}..."
  hdr = %w(email name company date_to source)
  CSV.open(new_affs_file, 'w', headers: hdr, force_quotes: true) do |csv|
    # csv << hdr
    new_affs.each { |row| csv << row }
  end
end

if ARGV.size < 5
  puts "Missing arguments: pr_data.txt pr_data.csv unknowns.csv all_affs.csv new_affs.csv"
  exit(1)
end

pr_data_to_csv(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4])
