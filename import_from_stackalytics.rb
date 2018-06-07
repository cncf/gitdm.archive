#!/usr/bin/env ruby

require 'pry'
require 'json'
require './email_code'
require './mgetc'

months = {
  '01': 'Jan',
  '02': 'Feb',
  '03': 'Mar',
  '04': 'Apr',
  '05': 'May',
  '06': 'Jun',
  '07': 'Jul',
  '08': 'Aug',
  '09': 'Sep',
  '10': 'Oct',
  '11': 'Nov',
  '12': 'Dec'
}

months_rev = {
  'Jan': '01',
  'Feb': '02',
  'Mar': '03',
  'Apr': '04',
  'May': '05',
  'Jun': '06',
  'Jul': '07',
  'Aug': '08',
  'Sep': '09',
  'Oct': '10',
  'Nov': '11',
  'Dec': '12'
}

existing = {}
File.readlines('cncf-config/email-map').each do |line|
  line = line.strip
  next if line[0] == '#'
  arr = line.split ' '
  email = email_encode(arr[0])
  company = arr[1..-1].join ' '
  didx = company.index(' < ')
  dtto = nil
  comp = company
  if didx
    comp = company[0..didx - 1]
    dtto = company[didx + 3..-1]
    a = dtto.split '-'
    dtto = "#{a[0]}-#{months[a[1].to_sym]}-#{a[2]}"
  end
  existing[email] = {} unless existing.key?(email)
  existing[email][comp] = [] unless existing[email].key?(comp)
  existing[email][comp] << dtto
end

data = JSON.parse File.read 'default_data.json'
# Some name transformations
slf = {}
slf['Self'] = true
slf['*independent'] = true
data['companies'][0]['aliases'].each do |als|
  slf[als] = true
end
data['users'].each do |user|
  comps = []
  user['companies'].each do |company|
    cname = company['company_name']
    dtto = company['end_date']
    if slf.key?(cname)
      cname = 'Independent'
    end
    rec = {}
    rec['company_name'] = cname
    rec['end_date'] = dtto
    comps << rec
  end
  user['companies'] = comps
end

conf1 = 0
conf2 = 0
newe = 0
newc = 0
same1 = 0
same2 = 0
miss = 0
skip_1to1 = {}

data['users'].each do |user|
  user['emails'].each do |email|
    email = email_encode email
    if existing.key?(email)
      user['companies'].each do |company|
        if existing[email].key?(company['company_name'])
          found = false
          existing[email][company['company_name']].each do |dt|
            if dt == company['end_date']
              found = true
              same1 += 1
              break
            end
          end
          unless found
            conf1 += 1
          end
        else
          if existing[email].keys.length == 1 && user['companies'].length == 1
            ecompany = existing[email].keys.first
            ncompany = company['company_name']
            break if skip_1to1[[ncompany, ecompany]]
          end
          puts "Email: #{email}"
          puts "Existing: #{existing[email]}"
          puts "New: #{company}"
          puts "Add?"
          #c = mgetc
          c = 'n'
          if c == 'q'
            exit 1
          elsif c != 'y'
            if existing[email].keys.length == 1 && user['companies'].length == 1
              ecompany = existing[email].keys.first
              ncompany = company['company_name']
              skip_1to1[[ncompany, ecompany]] = true
            end
            break
          end
          existing[email][company['company_name']] = [company['end_date']]
          newc += 1
        end
      end
      #existing[email].delete 'NotFound'
      existing[email].each do |ecompany, dttos|
        dttos.each do |dtto|
          found = false
          user['companies'].each do |company|
            if company['company_name'] == ecompany
              found = true
              if company['end_date'] != dtto
                conf2 += 1
              else
                same2 += 1
              end
              break
            end
          end
          unless found
            miss += 1
          end
        end
      end
    else
      user['companies'].each do |company|
        newe += 1
        existing[email] = {}
        existing[email][company['company_name']] = [company['end_date']]
      end
    end
  end
end

expired = []
mult = []
existing.each do |email, companies|
  nils = 0
  companies.each do |company, dttos|
    dttos.each do |dtto|
      if dtto.nil?
        nils += 1
      end
    end
  end
  if nils == 0
    expired << email
  elsif nils > 1
    mult << email
  end
end

File.open('email-map', 'w') do |file|
  existing.each do |email, companies|
    companies.each do |company, dttos|
      dttos.each do |dtto|
        if dtto
          a = dtto.split '-'
          dtto = "#{a[0]}-#{months_rev[a[1].to_sym]}-#{a[2]}"
          file.write "#{email} #{company} < #{dtto}\n"
        else
          file.write "#{email} #{company}\n"
        end
      end
    end
  end
end

puts "Skip_121: #{skip_1to1}"
puts "Same: #{same1}+#{same2}=#{same1+same2}, newe: #{newe}, newc: #{newc}, miss: #{miss}, conflict: #{conf1}+#{conf2}=#{conf1+conf2}, expired: #{expired.count}, multiple: #{mult.count}"
puts "Expired: #{expired}"
puts "Multiple: #{mult}"

#binding.pry
