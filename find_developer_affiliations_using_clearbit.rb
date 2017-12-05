# frozen_string_literal: true

# gem install clearbit
# requires ruby 2.3 or above
require 'pry'
require 'csv'
require 'Clearbit'
require 'json'
Clearbit.key = ENV['CLEARBIT_KEY']
# ask Rad at cabalrd@yahoo.com for an API key
# from a user set up for enrichment subscription
line_count = 0
start_found = false
email_list = []
text = File.open('all.txt').read
text.gsub!(/\r\n?/, '\n')
text.each_line do |line|
  # line_word_array = line.scan(/\d+/)
  line_word_array = line.split
  if !start_found && line_word_array[0] == 'Developers'
    start_found = true
  else
    next unless ['(Unknown)', 'NotFound'].include? line_word_array[0]
    email_list.push line_word_array[1]
    line_count += 1
  end
  # email_list.sort!
end

print "line count: #{line_count}\n"

# puts email_list.inspect
check_cnt = 1

ok_cnt = bad_cnt = err_cnt = 0

CSV.open('developer_affiliation_lookup_test.csv', 'w') do |csv|
  header_row = %w[email chance affiliation_suggestion hashed_email first_name]
  header_row << %w[last_name full_name gender localization bio site avatar]
  header_row << %w[employment_name employment_domain github_handle]
  header_row << %w[github_company github_blog googleplus_handle]
  header_row << %w[aboutme_handle gravatar_handle aboutme_bio]
  header_row.flatten!
  csv << header_row
  email_list.each do |email_with_at|
    # check_cnt is the max NUMBER of emails to PROCESS in this BATCH
    break if check_cnt > 1234
    email_with_exclamation = email_with_at.sub('!', '@')
    begin
      result =
        Clearbit::Enrichment.find(email: email_with_exclamation, stream: true)
      person = result.person
      temp_suggestion = 'NotFound'
      chance = 'none'
      first_name = person&.name&.given_name&.downcase
      last_name = person&.name&.family_name&.downcase
      person_employment_name_overwrite = true
      # binding.pry
      if !person&.employment&.name.nil? &&
         (person.employment.name == "#{first_name}#{last_name}" ||
         person.employment.name == "#{first_name} #{last_name}")
        temp_suggestion = 'Self'
        chance = 'none'
        person_employment_name_overwrite = false
      end
      if !person&.employment&.name.nil? &&
         (person.employment.name.downcase.include? 'university') &&
         (person.employment.name.downcase.include? 'institute') &&
         (person.employment.name.downcase.include? 'academy') &&
         !person&.github&.company.nil? && person.github.company != ''
        temp_suggestion = person.github.company
        chance = 'low'
      end
      if !person&.github&.company.nil? && person.github.company != '' &&
         person_employment_name_overwrite
        temp_suggestion = person.github.company
        chance = 'mid'
      end
      if !person&.employment&.name.nil? && person.employment.name != '' &&
         person.employment.name != 'GitHub' &&
         person_employment_name_overwrite
        temp_suggestion = person.employment.name
        chance = 'high'
      end
      suggestion = temp_suggestion
      csv_row = [person.email, chance, suggestion, email_with_at]
      csv_row.concat([person.name.given_name, person.name.family_name])
      csv_row.concat([person.name.fullName, person.gender, person.location])
      csv_row.concat([person.bio, person.site, person.avatar])
      csv_row.concat([person.employment.name, person.employment.domain])
      csv_row.concat([person.github.handle, person.github.company])
      csv_row.concat([person.github.blog, person.linkedin.handle])
      csv_row.concat([person.googleplus.handle, person.aboutme.handle])
      csv_row.concat([person.gravatar.handle, person.aboutme.bio])
      csv << csv_row
      ok_cnt += 1
      puts "#{check_cnt} got an enrichment"
    rescue StandardError => bang
      hash = JSON[bang]
      hash = JSON.parse(hash)
      if hash.index('email_invalid')
        csv << [email_with_at, 'none', 'NotFound', 'bad', 'email', 'address']
        bad_cnt += 1
        puts "#{check_cnt} received a bad email msg"
      else
        csv << [email_with_at, 'none', 'NotFound', 'error', 'bad', 'response']
        puts "#{check_cnt} #{bang}"
        err_cnt += 1
      end
    end
    check_cnt += 1
    # end
  end
end
puts 'done processing with Clearbit'
puts "count of found: #{ok_cnt}"
puts "count of bad emails: #{bad_cnt}"
puts "count of errored-out: #{err_cnt}"
