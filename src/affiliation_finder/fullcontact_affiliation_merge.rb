# frozen_string_literal: false

# read developer_affiliation_lookup.csv
# read email-map
# remove company suffixes such as Inc.,
# Everything with learning, university in its name is suspected to be Independent.
# maybe also 'institute', 'Software Engineer '
# Samsung SDS is separate from other Samsung
# Samsung Co., Samsung corp., Samsung Electronics, Samsung Mobile etc.
# They're all just Samsung. Also normalize samsung, Samsung, SAMSUNG etc.
# create map entries and insert appropriately
# if email listed has Independent or NotFound but new data
# has something then overwrite
# if data record is new, add
require 'csv'
require 'pry'
require '../comment'

line_count = 0
email_map_array = []
puts 'reading the email-map file'
text = File.open('../cncf-config/email-map').read
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
  replacements = ['GmbH & Co.', 'S.A.', 'Co.,', 'Co.', 'Co', 'Corp.,']
  replacements.concat(['Corp.', 'Corp', 'GmbH.,', 'GmbH.', 'GmbH'])
  replacements.concat(['Group.,', 'Group.', 'Group', 'Inc.,', 'Inc.'])
  replacements.concat(['Inc', 'Limited.,', 'Limited.', 'Limited'])
  replacements.concat(['LLC.,', 'LLC.', 'LLC', 'Ltd.,', 'Ltd.', 'Ltd'])
  replacements.concat(['PLC', 'S.à r.L.', ',Inc.', ',gmbh'])
  replacements.each do |replacement|
    affiliation_suggestion.sub!(/\s+#{replacement}$/i, '')
  end
  affiliation_suggestion.sub!(/^@/, '') # remove beginning @
  affiliation_suggestion.sub!(/^#/, '') # remove beginning #
  # affiliation_suggestion.sub!(/\.com$/, '') # remove ending .com
  affiliation_suggestion.sub!(/,$/, '') # remove ending comma
  affiliation_suggestion.sub!(/\.$/, '') # remove ending dot
  affiliation_suggestion.sub!(/\/$/, '') # remove ending slash
  return affiliation_suggestion
end

def check_for_self_employment(affiliation_suggestion)
  company_name = affiliation_suggestion&.downcase
  selfies = %w[learning university institute school freelance student]
  selfies.concat(['software engineer', 'self-employed', 'independent'])
  selfies.concat(['self employed', 'evangelist', 'enthusiast', 'self'])
  selfies.concat(['artist'])
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

def fix_huawei(affiliation_suggestion)
  # change GhostCloud . . . to GhostCloud
  company_name = affiliation_suggestion&.downcase
  affiliation_suggestion = 'Huawei' if company_name&.include? 'huawei '
  return affiliation_suggestion
end

def fix_possessive(affiliation_suggestion)
  # remove ' if company ends with '
  affiliation_suggestion&.sub(/'$/, '')
end

def apply_affiliation_fixes(affiliation_suggestion)
  affiliation_suggestion = correct_company_name(affiliation_suggestion)
  affiliation_suggestion = check_for_self_employment(affiliation_suggestion)
  affiliation_suggestion = fix_samsung(affiliation_suggestion)
  affiliation_suggestion = fix_hewlettpackard(affiliation_suggestion)
  affiliation_suggestion = fix_amazonwebservices(affiliation_suggestion)
  affiliation_suggestion = fix_soundcloud(affiliation_suggestion)
  affiliation_suggestion = fix_ghostcloud(affiliation_suggestion)
  affiliation_suggestion = fix_huawei(affiliation_suggestion)
  affiliation_suggestion = fix_possessive(affiliation_suggestion)
  return affiliation_suggestion.strip
end

def multi_affiliation_build(affiliation_multi)
  # org details pipe delimited:
  # organization_name
  # primary/secondary
  # current/past
  # start_date
  # end_date
  # title
  orgs = []
  for cnt in 1..10
    # orgs.flatten!
    org_details = affiliation_multi["org_#{cnt}"]
    next if org_details.nil?
    org_details = org_details.split('|')
    org_cnt_name = org_details[0] == '' ? 'missing_name' : org_details[0]
    org_name = apply_affiliation_fixes(org_cnt_name)
    org = [org_name, org_details[1], org_details[2], org_details[3], org_details[4], org_details[5]]
    orgs.push org
  end
  return orgs
end

affiliations = []
CSV.foreach('fullcontact_lookup_data.csv', headers: true) do |row|
  next if is_comment row
  affiliation_hash = row.to_h
  # affiliation_hash = asdf.to_h
  hashed_email = affiliation_hash['hashed_email']
  # base on columns: chance, affiliation_suggestion, hashed_email
  if affiliation_hash['org_1'].nil?
    affiliation = [hashed_email, 'NoMatchFound']
  else
    affiliation_build = multi_affiliation_build(affiliation_hash)
    affiliation = [hashed_email, 'match_found', 'orgs' => affiliation_build]
  end
  # binding.pry
  affiliations.push affiliation
end
puts "found #{affiliations.size} affiliations in fullcontact_lookup_data.csv"

# now check for existence to decide on update or insertion
added_mapping_count = updated_mapping_count = 0
text = File.read('../cncf-config/email-map')
affiliations.each do |affiliation|
  next if affiliation[1] == 'NoMatchFound' ||
          affiliation[2]['orgs'][0][0] == 'missing_name'

  curr_email = affiliation[0]
  curr_affil = affiliation[2]['orgs'][0][0]

  # new entry based on FullContact
  email_company_hash = "#{curr_email} #{curr_affil}"

  short_list = []
  email_map_array.each do |mapping_line|
    short_list.push mapping_line if mapping_line[0] == affiliation[0]
  end
  short_list_size = short_list.size
  if short_list_size.zero?
    text << "\n#{email_company_hash}"
    added_mapping_count += 1
  elsif short_list_size == 1
    if short_list[0][1] == 'Self'
      text = text.gsub(/#{affiliation[0]} Self/, email_company_hash)
      updated_mapping_count += 1
    elsif short_list[0][1] == 'Independent' &&
          curr_affil != 'Independent'
      text = text.gsub(/#{affiliation[0]} Independent/, email_company_hash)
      updated_mapping_count += 1
    end
  end
end

if added_mapping_count.positive? || updated_mapping_count.positive?
  # Write changes back to the file
  File.open('../cncf-config/email-map', 'w') { |file| file.puts text }

  puts 'altered the email-map file with Clearbit suggestions'
  puts "updated #{updated_mapping_count} records"
  puts "added #{added_mapping_count} records"

  new_array = File.readlines('../cncf-config/email-map').sort
  File.open('../cncf-config/email-map', 'w') do |file|
    file.puts new_array
  end
  puts 'sorted email-map'
end

# Save multi-org developer work history to a separate file
CSV.open('fullcontact_developer_historical_organizations.csv', 'w') do |csv|
  header_row = ['email/org_name', 'category', 'timing', 'date_from', 'date_to', 'title']
  csv << header_row
  affiliations.each do |affiliation|
    next if affiliation[1] == 'NoMatchFound' || affiliation[2]['orgs'][1].nil?
    csv << [affiliation[0]] # email address
    affiliation[2]['orgs'].each do |dev_org|
      if !dev_org.nil?
        csv << [dev_org[0], dev_org[1], dev_org[2], dev_org[3], dev_org[4], dev_org[5]]
      end
    end
    csv << [''] # empty row to separate developers visually
  end
end

puts 'exported developer organizations to fullcontact_developer_historical_organizations.csv'

puts 'all done'
