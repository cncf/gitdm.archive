#read developer_affiliation_lookup.csv
#read email-map
#remove company suffixes such as Inc.,
#Everything with 'learning', 'university', in its name is suspected to be Self. maybe also 'institute', 'Software Engineer '
#Samsung SDS is separate from other Samsung 
#Samsund Co., Samsung corp., Samsung Electronics, Samsung Mobile etc. They're all just Samsung.
#Also normalize samsung, Samsung, SAMSUNG etc.
#create map entries and insert appropriately
#if email found and has something other than self or notfound but new data has something, overwrite
#if data record is new, add
#self is to be capitalized - Self
#unknown is to be marked NotFound
require 'csv'
require 'pry'
require './comment'

line_count = 0
email_map_list = []
puts 'reading the email-map file'
text = File.open('cncf-config/email-map').read
text.gsub!(/\r\n?/, '\n')
text.each_line do |line|
  line_word_array = line.gsub(/\s+/m, ' ').strip.split(' ')
  if line_word_array[0] != '#'
    email_map_list.push line_word_array
    line_count += 1
  end
end
puts "found #{line_count} mappings in email-map file"

def correct_company_name(affiliation_suggestion)
    #puts "received #{affiliation_suggestion}"
    #remove suffixes like: Co., Ltd., Corp., Inc., Limited., LLC, Group. from company names.
    replacement_array = [' GmbH & Co.',' S.A.',' Co.,',' Co.',' Co',' Corp.,',' Corp.',' Corp',' GmbH.,',' GmbH.',' GmbH',' Group.,',' Group.',' Group',' Inc.,', ' Inc.',' Inc',' Limited.,',' Limited.',' Limited',' LLC.,',' LLC.',' LLC',' Ltd.,',' Ltd.',' Ltd',' PLC',' S.à r.L.']
    replacement_array.each do |replacement_item|
      affiliation_suggestion.sub!(replacement_item,'')
    end
    affiliation_suggestion.sub!(/^@/, '')    #remove begigging @
    affiliation_suggestion.sub!(/.com$/, '') #remove ending .com
    #puts "returned #{affiliation_suggestion}"
    #binding.pry
    return affiliation_suggestion
  end

  def check_for_self_employment(affiliation_suggestion)
    company_name = affiliation_suggestion&.downcase
    selfies = ['learning','university','institute','school','software engineer','self-employed','self employed','evangelist','enthusiast','self']
    selfies.each do |selfie|    
      if company_name.include? selfie
       affiliation_suggestion = 'Self'
     end
   end
   return affiliation_suggestion
 end

 def normalize_samsung(affiliation_suggestion)
    #Samsung SDS is separate from other Samsung 
    #Samsundg Co., Samsung corp., Samsung Electronics, Samsung Mobile etc. They're all just Samsung, proper case
    company_name = affiliation_suggestion&.downcase
    if company_name&.include? 'samsung'
      affiliation_suggestion.gsub(/samsung/i, 'Samsung')
    end
    if ['samsung electronics','samsung mobile'].include? "#{company_name}"
      affiliation_suggestion = 'Samsung'
    end
    return affiliation_suggestion
  end

  def normalize_hewlettpackard(affiliation_suggestion)
    #HP and Hewlett-Packard to HPE
    company_name = affiliation_suggestion&.downcase
    if ['hewlett-packard','hewlettpackard','hewlett packard','hp'].include? "#{company_name}"
      affiliation_suggestion = 'HPE'
    end
    return affiliation_suggestion
  end

  def normalize_amazonwebservices(affiliation_suggestion)
    #change Amazon Web Services to AWS
    company_name = affiliation_suggestion&.downcase
    if company_name&.include? 'amazon web services'
      affiliation_suggestion = 'AWS'
    end
    return affiliation_suggestion
  end

  def normalize_soundcloud(affiliation_suggestion)
    #change SoundCloud … to SoundCloud
    company_name = affiliation_suggestion&.downcase
    if company_name&.include? 'soundcloud '
      affiliation_suggestion = 'SoundCloud'
    end
    return affiliation_suggestion
  end

  def normalize_ghostcloud(affiliation_suggestion)
    #change GhostCloud … to GhostCloud
    company_name = affiliation_suggestion&.downcase
    if company_name&.include? 'ghostcloud '
      affiliation_suggestion = 'Ghostcloud'
    end
    return affiliation_suggestion
  end

  def normalize_possessive(affiliation_suggestion)
    #remove ' if company ends with '
    affiliation_suggestion&.sub!(/'$/, '')
    return affiliation_suggestion
  end

  suggestions = []
  CSV.foreach('developer_affiliation_lookup.csv', headers: true) do |row|
    next if is_comment row
    affiliation_hash = row.to_h
    affiliation_suggestion = affiliation_hash['affiliation_suggestion']
    # add emails with no company as NotFound
    # if company is name associated with email, do Self
    # base on columns: chance, affiliation_suggestion, hashed_email
    if ['high','mid','low'].include? affiliation_hash['chance']
      affiliation_suggestion = correct_company_name(affiliation_suggestion)
      affiliation_suggestion = check_for_self_employment(affiliation_suggestion)
      affiliation_suggestion = normalize_samsung(affiliation_suggestion)
      affiliation_suggestion = normalize_hewlettpackard(affiliation_suggestion)
      affiliation_suggestion = normalize_amazonwebservices(affiliation_suggestion)
      affiliation_suggestion = normalize_soundcloud(affiliation_suggestion)
      affiliation_suggestion = normalize_ghostcloud(affiliation_suggestion)
      affiliation_suggestion = normalize_possessive(affiliation_suggestion)
      suggestion = [ affiliation_hash['hashed_email'], affiliation_suggestion ]
        #binding.pry
        suggestions.push suggestion
    else #add Unknowns
      suggestion = [ affiliation_hash['hashed_email'], 'NotFound' ]
      suggestions.push suggestion
    end
  end
  puts "found #{suggestions.size} suggestions in developer_affiliation_lookup.csv file"

#now check for existence to decide on update or insertion
added_mapping_count = updated_mapping_count = 0
text = File.read('cncf-config/email-map')
suggestions.each do |suggestion|
#suggestion[1] can be a company name or Self or NotFound

#if email found and has something other than self or notfound but new data has something, overwrite
#if data record is new, add

email_company_hash = "#{suggestion[0]} #{suggestion[1]}"
email_company_text = "#{email_company_hash}\n" #new entry based on Clearbit

if !['Self', 'NotFound'].include? suggestion[1]
  if !text.include? email_company_text
      # append to end if the email does not already have a company assigment
      short_list = []
      email_map_list.each do |mapping_line|
        if mapping_line[0] == suggestion[0]
          short_list.push "#{mapping_line[0]} #{mapping_line[1]}"
        end
      end
      if !short_list.include? email_company_hash
        text << email_company_text
        added_mapping_count += 1
      end
    end
  else
    if (!['Self', 'NotFound'].include? "#{suggestion[1]}") && (text.include? "#{suggestion[0]} Self")
      # replace existing Self with a company
      text = text.gsub(/#{suggestion[0]} Self/, email_company_text)
      updated_mapping_count += 1
    elsif suggestion[1] == 'Self' && (text.include? "#{suggestion[0]} NotFound")
      # replace existing NotFound with Self
      text = text.gsub(/#{suggestion[0]} NotFound/, email_company_text)
      updated_mapping_count += 1
    end
  end
end

# Write changes back to the file
File.open('cncf-config/email-map', 'w') {|file| file.puts text }

puts 'altered the email-map file with Clearbit suggestions'
puts "updated #{updated_mapping_count} records}"
puts "added #{added_mapping_count} records}"

new_array = File.readlines('cncf-config/email-map').sort
File.open('cncf-config/email-map','w') do |file|
  file.puts new_array
end

puts 'sorted email-map'

puts 'all done'
