#!/usr/bin/env ruby

require 'csv'
require 'pry'

require './email_code'

def pr_data_to_csv(pr_data_file)
  companies = []
  emails = []
  name = ''
  n = 0
  File.readlines(pr_data_file).each do |line|
    n += 1
    line = email_encode(line.delete(" \t\r\n"))
    ary = line.split(':')
    if ary.length == 2
      if companies.length > 0
        # p [name, emails, companies]
      end
      companies = []
      name = ary[0]
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
        puts "Invalid affiliation config, line #{n}: #{line}"
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
end

if ARGV.size < 1
  puts "Missing arguments: pr_data.txt"
  exit(1)
end

pr_data_to_csv(ARGV[0])
