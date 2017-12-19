# frozen_string_literal: true

# gem install clearbit
# requires ruby 2.3 or above
require 'pry'
require 'csv'
require 'json'
require 'Clearbit'

Clearbit.key = ENV['CLEARBIT_KEY']
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
  # email_list.sort!
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

def person_is_a_student(employment_hint)
  learning_keywords = %w[university institute academy school]
  result = false
  learning_keywords.each do |learning_keyword|
    result = true if employment_hint.include? learning_keyword
  end
  return result
end

def not_a_blank_string(var_to_check)
  if var_to_check.nil? || !(var_to_check.is_a? String) || var_to_check.empty?
    return false
  else
    return true
  end
end

CSV.open('clearbit_lookup_data.csv', 'w') do |csv|
  header_row = %w[email chance affiliation_suggestion hashed_email first_name]
  header_row << %w[last_name full_name gender localization bio site avatar]
  header_row << %w[employment_name employment_domain github_handle]
  header_row << %w[github_company github_blog linkedin_handle googleplus_handle]
  header_row << %w[aboutme_handle gravatar_handle aboutme_bio]
  header_row.flatten!
  csv << header_row
  email_list.each do |email_with_exclamation|
    # check_cnt is the max NUMBER of emails to PROCESS in this BATCH
    break if check_cnt > 1234
    begin
      email_with_at = email_with_exclamation.sub('!', '@')
      next if !email_with_at.include? '@'
      result =
        Clearbit::Enrichment.find(email: email_with_at, stream: true)
      raise 'no response from Clearbit' if result.nil?
      raise 'no Person node in Clearbit json' if result.person.nil?
      person = result.person
      temp_suggestion = 'NoMatchFound'
      chance = 'none'
      first_name = person&.name&.given_name
      last_name = person&.name&.family_name
      first_last = "#{first_name}#{last_name}"&.rstrip
      first_space_last = "#{first_name} #{last_name}".rstrip
      bad_employment = [first_last, first_space_last]
      person_company = person&.employment&.name
      gh_company = person&.github&.company
      person_employment_name_overwrite = true
      # binding.pry
      if not_a_blank_string(person_company) &&
         bad_employment.include?(person_company)
        temp_suggestion = 'Independent'
        chance = 'none'
        person_employment_name_overwrite = false
      end
      if not_a_blank_string(person_company) &&
         person_is_a_student(person_company) &&
         not_a_blank_string(gh_company)
        temp_suggestion = gh_company
        chance = 'low'
      end
      if !not_a_blank_string(person_company) && not_a_blank_string(gh_company)
        temp_suggestion = person.github.company
        chance = 'mid'
      end
      if not_a_blank_string(person_company) && person_company != 'GitHub' &&
         person_employment_name_overwrite
        temp_suggestion = person_company
        chance = 'high'
      end
      suggestion = temp_suggestion
      csv_row = [email_with_at, chance, suggestion, email_with_exclamation]
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
        csv << [email_with_at, 'none', 'NoMatchFound', 'bad', 'email', 'address']
        bad_cnt += 1
        puts "#{check_cnt} received a bad email msg"
      else
        csv << [email_with_at, 'none', 'NoMatchFound', 'error', 'bad', 'response']
        puts "#{check_cnt} #{bang}"
        err_cnt += 1
      end
    end
    check_cnt += 1
  end
end
puts 'done processing with Clearbit'
puts "count of found: #{ok_cnt}"
puts "count of bad emails: #{bad_cnt}"
puts "count of errored-out: #{err_cnt}"
