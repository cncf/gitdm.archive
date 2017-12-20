# frozen_string_literal: true

# gem install fullcontact
# requires ruby 2.3 or above
require 'pry'
require 'csv'
require 'json'
require 'fullcontact'

FullContact.configure do |config|
  config.api_key = ENV['FULLCONTACT_KEY']
end
# ask Rad at cabalrd@yahoo.com for an API key
# from a user set up for enrichment subscription
line_count = 0
start_found = false
email_list = []
text = File.open('../all.txt').read
text.gsub!(/\r\n?/, '\n')
text.each_line do |line|
  # line_word_array = line.scan(/\d+/)
  line_word_array = line.split
  if !start_found && line == "Developers with unknown affiliation\n"
    start_found = true
  elsif start_found
    break if line == "\n"
    email_list.push line_word_array[1]
    line_count += 1
  end
end
start_found = false
text.each_line do |line|
  # line_word_array = line.scan(/\d+/)
  line_word_array = line.split
  if !start_found && line == "Developers working on their own behalf\n"
    start_found = true
  elsif start_found
    break if line == "\n"
    email_list.push line_word_array[1]
    line_count += 1
  end
  # email_list.sort!
end

print "line count: #{line_count}\n"
# puts email_list.inspect
check_cnt = 1

ok_cnt = bad_cnt = err_cnt = 0

CSV.open('fullcontact_lookup_data.csv', 'w') do |csv|
  header_row = %w[full_name gender localization hashed_email]
  header_row << %w[org_1 org_2 org_3 org_4 org_5 org_6 org_7 org_8 org_9 org_10]
  header_row << %w[github_handle linkedin_handle aboutme_handle]
  header_row << %w[googleplus_handle gravatar_handle]
  header_row.flatten!
  csv << header_row
  email_list.each do |email_with_exclamation|
    # check_cnt is the max NUMBER of emails to PROCESS in this BATCH
    break if check_cnt > 1200
    begin
      email_with_at = email_with_exclamation.sub('!', '@')
      next if !email_with_at.include? '@'
      person = FullContact.person(email: email_with_at)
      raise 'FullContact_lookup_failed' if person.nil?
      raise person if person.status != 200
      orgs = []
      org_cnt = 1

      aboutme_handle = github_handle = googleplus_handle = ''
      gravatar_handle = linkedin_handle = ''

      if !person&.organizations.nil?
        person.organizations.each do |organization|
          org_details = ''
          org_details += organization.name.nil? ? 'missing_name|' : "#{organization.name}|"
          organization.is_primary ? (org_details += 'primary|') : (org_details += 'secondary|')
          organization.current ? (org_details += 'current|') : (org_details += 'past|')
          org_details += "#{organization.start_date}|"
          org_details += "#{organization.end_date}|"
          org_details += organization.title.nil? ? '' : organization.title
          orgs[org_cnt] = org_details
          org_cnt += 1
        end
      end

      if !person&.social_profiles.nil?
        person.social_profiles.each do |social_profile|
          case social_profile.type_id
          when 'aboutme'
            aboutme_handle = social_profile.username
          when 'github'
            github_handle = social_profile.username
          when 'google'
            googleplus_handle = social_profile.username
          when 'gravatar'
            gravatar_handle = social_profile.username
          when 'linkedin'
            linkedin_handle = social_profile.username
          end
        end
      end

      csv_row = [person.contact_info&.full_name, person.demographics&.gender]
      csv_row.concat([person.demographics&.location_general])
      csv_row.concat([email_with_exclamation])
      csv_row.concat([orgs[1], orgs[2], orgs[3], orgs[4], orgs[5]])
      csv_row.concat([orgs[6], orgs[7], orgs[8], orgs[9], orgs[10]])
      csv_row.concat([github_handle, linkedin_handle, aboutme_handle])
      csv_row.concat([googleplus_handle, gravatar_handle])
      csv << csv_row
      ok_cnt += 1
      puts "#{check_cnt} got an enrichment for #{email_with_exclamation}"
    rescue StandardError => bang
      if bang.is_a? String
        csv << ['error', 'bad', 'email', email_with_exclamation]
        bad_cnt += 1
        puts "#{check_cnt} #{email_with_exclamation}received a bad email msg"
      else
        csv << ['error', 'invalid', 'response', email_with_exclamation]
        puts "#{check_cnt} #{email_with_exclamation}\n#{bang}"
        err_cnt += 1
      end
    end
    check_cnt += 1
  end
end
puts 'done processing with FullContact'
puts "count of found: #{ok_cnt}"
puts "count of bad emails: #{bad_cnt}"
puts "count of errored-out: #{err_cnt}"
