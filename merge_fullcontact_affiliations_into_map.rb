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
# independent is to be capitalized - Independent
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
  return affiliation_suggestion
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
    if !org_details.nil?
      org_details = org_details.split("|")
      org_cnt_name = org_details[0] == '' ? 'Independent' : org_details[0]
      org_name = apply_affiliation_fixes(org_cnt_name)
      org = [org_name, org_details[1], org_details[2], org_details[3], org_details[4], org_details[5]]
      orgs.push (org)
    end
  end
  return orgs
end

affiliations = []
CSV.foreach('fullconact_developer_affiliation.csv', headers: true) do |row|
  next if is_comment row
  affiliation_hash = row.to_h
  #affiliation_hash = asdf.to_h
  hashed_email = affiliation_hash['hashed_email']
  # base on columns: chance, affiliation_suggestion, hashed_email
  if affiliation_hash['org_1'].nil?
    affiliation = [hashed_email, 'NotFound']
  else
    affiliation_build = multi_affiliation_build( affiliation_hash)
    affiliation = [hashed_email, 'match_found', 'orgs' => affiliation_build]
  end
  # binding.pry
  affiliations.push affiliation
end
puts "found #{affiliations.size} affiliations in developer_affiliation_lookup.csv"

# now check for existence to decide on update or insertion
added_mapping_count = updated_mapping_count = 0
text = File.read('cncf-config/email-map')
affiliations.each do |affiliation|
  # affiliation[1] can be a company name or Independent or NotFound

  # if data record is new then add
  # if email found and has something other than Independent or NotFound
  # but new data has something then overwrite conditions based

  # new entry based on FullContact
  curr_email = affiliation[0]
  curr_affil = affiliation[1]
  if curr_affil != 'NotFound'
    curr_affil = affiliation[2]['orgs'][0][0]
    # binding.pry
    # sample data:
    # org name | category | timing | from | to | title

    # amim.knabben!gmail.com
    # Axado  |primary  |current  |2015-10  |     |Python Developer

    # thomasf!jossystem.se
    # Jossystem       |primary    |current  |2002     |     |Artist
    # 23c             |secondary  |current  |2012-05  |     |All Parts of Creating and Running Software and Services
    # Thomas Frössman |secondary  |current  |1998     |     |Artist and Music and Sound and DJ and Information Technology and General Stuff

    # outtatime!gmail.com
    # Gigawatt IO              |primary    |current|2014-06  |         |
    # ThreatStream Inc.        |secondary  |past   |2013-12  |2015     |Senior Director of Engineering
    # SendHub                  |secondary  |past   |2012-04  |2013-10  |Director of Platform
    # Klout                    |secondary  |past   |2010-10  |2012-04  |Engineering Manager
    # RockYou!                 |secondary  |past   |2010-04  |2010-10  |Software Engineering Team Lead
    # Gigawatt                 |secondary  |current|2015     |         |Founder
    # ThreatStream             |secondary  |past   |2014     |2015     |Senior Director of Engineering
    # Klout, Inc.              |secondary  |past   |2010     |2012     |Software Engineer
    # Bloosky Interactive      |secondary  |past   |2008     |2009     |Software Enginner
    # Veracity Communications  |secondary  |past   |2008     |2009     |Software Engineer

    # TODO: maybe handle multi-org emails
    # currently org_1 is taken for multi-org emails

  end
  email_company_hash = "#{curr_email} #{curr_affil}"

  short_list = []
  email_map_array.each do |mapping_line|
    short_list.push mapping_line if mapping_line[0] == affiliation[0]
  end
  short_list_size = short_list.size
  if short_list_size.zero?
    text << "\n#{email_company_hash}"
    added_mapping_count += 1
  elsif short_list_size == 1 && short_list[0][1] == 'Independent' &&
        !%w[Independent NotFound].include?(affiliation[1])
    text = text.gsub(/#{affiliation[0]} Independent/, email_company_hash)
    updated_mapping_count += 1
  end
end

# Write changes back to the file
File.open('cncf-config/email-map', 'w') { |file| file.puts text }

puts 'altered the email-map file with FullContact affiliations'
puts "updated #{updated_mapping_count} records"
puts "added #{added_mapping_count} records"

new_array = File.readlines('cncf-config/email-map').sort
File.open('cncf-config/email-map', 'w') do |file|
  file.puts new_array
end

puts 'sorted email-map'

puts 'all done'
