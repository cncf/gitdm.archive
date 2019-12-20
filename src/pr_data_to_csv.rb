#!/usr/bin/env ruby

require 'csv'
require 'pry'

require './email_code'

def process_affiliation(uname, name, emails, companies)
  # type,email,name,github,linkedin1,linkedin2,linkedin3,commits,gender,location,affiliations,new emails
  ['(Unknown)', emails.join(', '), uname, "https://github.com/#{name}", '', '', '', '0', '', '', companies.join(','), '']
end

def pr_data_to_csv(pr_data_file, csv_file)
  companies = []
  emails = []
  name = ''
  uname = ''
  n = 0
  data = []
  File.readlines(pr_data_file).each do |line|
    n += 1
    line = email_encode(line.delete(" \t\r\n"))
    ary = line.split(':')
    if ary.length == 2
      if companies.length > 0
        data << process_affiliation(uname, name, emails, companies)
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
  end
  puts "Writting #{csv_file}..."
  hdr = %w(type email name github linkedin1 linkedin2 linkedin3 commits gender location affiliations)
  hdr << 'new emails'
  CSV.open(csv_file, 'w', headers: hdr) do |csv|
    csv << hdr
    data.each { |row| csv << row }
  end
end

if ARGV.size < 2
  puts "Missing arguments: pr_data.txt output.csv"
  exit(1)
end

pr_data_to_csv(ARGV[0], ARGV[1])
