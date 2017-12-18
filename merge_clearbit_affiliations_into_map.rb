# frozen_string_literal: false

# read developer_affiliation_lookup.csv
# read email-map
# remove company suffixes such as Inc.,
# Everything with learning, university in its name is suspected to be Independent.
# maybe also 'institute', 'Software Engineer '
# Samsung SDS is separate from other Samsung
# Samsund Co., Samsung corp., Samsung Electronics, Samsung Mobile etc.
# They're all just Samsung. Also normalize samsung, Samsung, SAMSUNG etc.
# create map entries and insert appropriately
# if email found and has something other than Independent or NotFound but new data
# has something, overwrite
# if data record is new, add
# Independent is to be capitalized - Independent
# unknown is to be marked NotFound
require 'csv'
require 'pry'
require './comment'

line_count = 0
email_map_array = []
puts 'reading the email-map file'
text = File.open('cncf-config/email-map').read
text.gsub!(/\r\n?/, '\n')
text.each_line do |line|
  line_word_array = line.gsub(/\s+/m, ' ').strip.split(' ')
  if line_word_array[0] != '#'
    email_map_array.push line_word_array
    line_count += 1
  end
end
puts "found #{line_count} mappings in email-map file"

def correct_company_name(affiliation_suggestion)
  # puts "received #{affiliation_suggestion}"
  # remove suffixes like: Co., Ltd., Corp., Inc., Limited., LLC,
  # Group. from company names.
  replacements = [' GmbH & Co.', ' S.A.', ' Co.,', ' Co.', ' Co', ' Corp.,']
  replacements.concat([' Corp.', ' Corp', ' GmbH.,', ' GmbH.', ' GmbH'])
  replacements.concat([' Group.,', ' Group.', ' Group', ' Inc.,', ' Inc.'])
  replacements.concat([' Inc', ' Limited.,', ' Limited.', ' Limited'])
  replacements.concat([' LLC.,', ' LLC.', ' LLC', ' Ltd.,', ' Ltd.', ' Ltd'])
  replacements.concat([' PLC', ' S.à r.L.', ', Inc.', ', gmbh'])
  replacements.each do |replacement|
    affiliation_suggestion.sub!(replacement, '')
  end
  affiliation_suggestion.sub!(/^@/, '') # remove begigging @
  # affiliation_suggestion.sub!(/.com$/, '') # remove ending .com
  affiliation_suggestion.sub!(/,$/, '') # remove ending comma
  affiliation_suggestion.sub!(%r{/\/$/}, '') # remove ending slash
  return affiliation_suggestion
end

def check_for_self_employment(affiliation_suggestion)
  company_name = affiliation_suggestion&.downcase
  selfies = %w[learning university institute school freelance student]
  selfies.concat(['software engineer', 'self-employed', 'independent'])
  selfies.concat(['self employed', 'evangelist', 'enthusiast', 'self'])
  selfies.each do |selfie|
    affiliation_suggestion = 'Independent' if company_name&.include? selfie
  end
  return affiliation_suggestion
end

def fix_samsung(affiliation_suggestion)
  # Samsung SDS is separate from other SamsungS
  # Samsundg Co., Samsung corp., Samsung Electronics, Samsung Mobile etc.
  # They're all just Samsung, proper case
  company_name = affiliation_suggestion&.downcase
  if company_name&.include? 'samsung'
    affiliation_suggestion = affiliation_suggestion.gsub(/samsung/i, 'Samsung')
  end
  if ['samsung electronics', 'samsung mobile'].include? company_name
    affiliation_suggestion = 'Samsung'
  end
  return affiliation_suggestion
end

def fix_hewlettpackard(affiliation_suggestion)
  # HP and Hewlett-Packard to HPE
  company_name = affiliation_suggestion&.downcase
  aka_hpe = ['hewlett-packard', 'hewlettpackard', 'hewlett packard', 'hp']
  affiliation_suggestion = 'HPE' if aka_hpe.include? company_name
  return affiliation_suggestion
end

def fix_amazonwebservices(affiliation_suggestion)
  # change Amazon Web Services to AWS
  company_name = affiliation_suggestion&.downcase
  aws_normalized = 'amazon web services'
  affiliation_suggestion = 'AWS' if company_name&.include? aws_normalized
  return affiliation_suggestion
end

def fix_soundcloud(affiliation_suggestion)
  # change SoundCloud . . . to SoundCloud
  company_name = affiliation_suggestion&.downcase
  affiliation_suggestion = 'SoundCloud' if company_name&.include? 'soundcloud '
  return affiliation_suggestion
end

def fix_ghostcloud(affiliation_suggestion)
  # change GhostCloud . . . to GhostCloud
  company_name = affiliation_suggestion&.downcase
  affiliation_suggestion = 'Ghostcloud' if company_name&.include? 'ghostcloud '
  return affiliation_suggestion
end

def fix_possessive(affiliation_suggestion)
  # remove ' if company ends with '
  affiliation_suggestion&.sub(/'$/, '')
end

suggestions = []
CSV.foreach('developer_affiliation_lookup.csv', headers: true) do |row|
  next if is_comment row
  affiliation_hash = row.to_h
  affiliation_suggestion = affiliation_hash['affiliation_suggestion']
  hashed_email = affiliation_hash['email'].sub('@', '!')
  # base on columns: chance, affiliation_suggestion, hashed_email
  if %w[high mid low none].include? affiliation_hash['chance']
    # puts "a #{affiliation_suggestion}"
    affiliation_suggestion = correct_company_name(affiliation_suggestion)
    affiliation_suggestion = check_for_self_employment(affiliation_suggestion)
    affiliation_suggestion = fix_samsung(affiliation_suggestion)
    affiliation_suggestion = fix_hewlettpackard(affiliation_suggestion)
    affiliation_suggestion = fix_amazonwebservices(affiliation_suggestion)
    affiliation_suggestion = fix_soundcloud(affiliation_suggestion)
    affiliation_suggestion = fix_ghostcloud(affiliation_suggestion)
    affiliation_suggestion = fix_possessive(affiliation_suggestion)
    # puts "b #{affiliation_suggestion}"
    suggestion = [hashed_email, affiliation_suggestion]
    # binding.pry
  else # add Unknowns
    suggestion = [hashed_email, 'NotFound']
  end
  suggestions.push suggestion
end
puts "found #{suggestions.size} suggestions in developer_affiliation_lookup.csv"

# now check for existence to decide on update or insertion
added_mapping_count = updated_mapping_count = 0
text = File.read('cncf-config/email-map')
suggestions.each do |suggestion|
  # suggestion[1] can be a company name or Independent or NotFound

  # if data record is new then add
  # if email found and has something other than Independent or NotFound
  # but new data has something then overwrite conditions based

  # new entry based on Clearbit
  email_company_hash = "#{suggestion[0]} #{suggestion[1]}"

  short_list = []
  email_map_array.each do |mapping_line|
    short_list.push mapping_line if mapping_line[0] == suggestion[0]
  end
  short_list_size = short_list.size
  if short_list_size.zero?
    text << "\n#{email_company_hash}"
    added_mapping_count += 1
  elsif short_list_size == 1 && short_list[0][1] == 'Independent' &&
        !%w[Independent NotFound].include?(suggestion[1])
    text = text.gsub(/#{suggestion[0]} Independent/, email_company_hash)
    updated_mapping_count += 1
  end
end

# Write changes back to the file
File.open('cncf-config/email-map', 'w') { |file| file.puts text }

puts 'altered the email-map file with Clearbit suggestions'
puts "updated #{updated_mapping_count} records"
puts "added #{added_mapping_count} records"

new_array = File.readlines('cncf-config/email-map').sort
File.open('cncf-config/email-map', 'w') do |file|
  file.puts new_array
end

puts 'sorted email-map'

puts 'all done'
