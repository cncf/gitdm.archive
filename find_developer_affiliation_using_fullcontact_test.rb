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

# puts email_list.inspect
check_cnt = 1

ok_cnt = bad_cnt = err_cnt = 0

CSV.open('fullconact_developer_affiliation_test.csv', 'w') do |csv|
  header_row = %w[full_name gender localization hashed_email]
  header_row << %w[org_1 org_2 org_3 org_4 org_5 org_6 org_7 org_8 org_9 org_10]
  header_row << %w[github_handle linkedin_handle aboutme_handle]
  header_row << %w[googleplus_handle gravatar_handle]
  header_row.flatten!
  csv << header_row
  person = FullContact.person(email: 'alostengineer@users.noreply.github.com')
  raise 'FullContact_lookup_failed' if person.nil?
  raise person if person.status != 200
  orgs = []
  org_cnt = 1

  aboutme_handle = github_handle = googleplus_handle = ''
  gravatar_handle = linkedin_handle = ''

  if !person&.organizations.nil?
    person.organizations.each do |organization|
      org_details = ''
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
end
puts 'done processing with FullContact'
puts "count of found: #{ok_cnt}"
puts "count of bad emails: #{bad_cnt}"
puts "count of errored-out: #{err_cnt}"
