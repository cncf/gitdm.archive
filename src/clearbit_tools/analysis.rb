require 'csv'
require 'pry'

statuses = {}
emails = {}
emails2 = {}
keys = {}

# new_round_enriched.csv
CSV.foreach('./all_clearbit_queries.csv', headers: true) do |row|
  h = row.to_h
  status = h['status']
  email = h['source']
  employment = h['person_employment_name']
  statuses[status] = [] unless statuses.key? status
  statuses[status] << email 
  next unless status == 'found'
  if employment != ''
    emails[email] = [] unless emails.key? email
    emails[email] << employment
    next
  end
  full_name = h['person_name_full_name']
  if full_name != ''
    emails2[email] = [] unless emails.key? email
    emails2[email] << full_name
    next
  end
  h.each do |key, value|
    keys[key] = [0, 0] unless keys.key? key
    if value != ''
      keys[key][0] += 1
    else
      keys[key][1] += 1
    end
  end
end

CSV.foreach('./unknown_devs.csv', headers: true) do |row|
  h = row.to_h
  e = h['email']
  if emails.key? e
    puts "#{e} #{emails[e].first}"
  end
end

found = []
keys.each do |key, value|
  found << [key, value[0], value[1]]
end

found = found.sort_by { |item| -item[1] }

#emails.each do |email, company|
#  puts "#{email.strip} #{company.first.strip}"
#end

#emails2.each do |email, full_name|
#  puts "#{email.strip} #{full_name.first.strip}"
#end

