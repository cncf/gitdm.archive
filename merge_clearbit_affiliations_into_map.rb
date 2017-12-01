#read developer_affiliation_lookup.csv
#read email-map
#remove company suffixes such as Inc.,
#Everything with "learning", "university", in its name is suspected to be Self. maybe also "institute", "Software Engineer "
#Samsung SDS is separate from other Samsung 
#Samsund Co., Samsung corp., Samsung Electronics, Samsung Mobile etc. They're all just Samsung.
#Also normalize samsung, Samsung, SAMSUNG etc.
#create map entries and insert appropriately
#if email found and has something other than self or notfound but new data has something, overwrite
#if data record is new, add
#self is to be propercase - Self
#unknown is to be marked NotFound
require 'csv'
require 'pry'
require './comment'

line_num = 0
map_list = []
puts "reading the email-map file"
text = File.open('cncf-config/email-map').read
text.gsub!(/\r\n?/, "\n")
text.each_line do |line|
	sl = line.gsub(/\s+/m, ' ').strip.split(" ")
	if sl[0] != '#'
	  map_list.push sl
	  line_num += 1
	end
end
puts "found #{line_num} mappings in email-map file"

def correct_company_name(a_s)
	#puts "received #{a_s}"
	#remove suffixes like: Co., Ltd., Corp., Inc., Limited., LLC, Group. from company names.
	ra = [" GmbH & Co."," S.A."," Co.,"," Co."," Co"," Corp.,"," Corp."," Corp"," GmbH.,"," GmbH."," GmbH"," Group.,"," Group."," Group"," Inc.,", " Inc."," Inc"," Limited.,"," Limited."," Limited"," LLC.,"," LLC."," LLC"," Ltd.,"," Ltd."," Ltd"," PLC"," S.à r.L."]
	ra.each do |sg|
		a_s.sub!(sg,"")
	end
	a_s.sub!(/^@/, "")    #remove begigging @
	a_s.sub!(/.com$/, "") #remove ending .com
	#puts "returned #{a_s}"
	#binding.pry
    return a_s
end

def check_for_self_employment(a_s)
	cn = a_s&.downcase
	selfies = ["learning","university","institute","school","software engineer","self-employed","self employed","evangelist","enthusiast","self"]
	selfies.each do |selfie|	
		if cn.include? selfie
		   a_s = "Self"
		end
	end
	return a_s
end

def normalize_samsung(a_s)
	#Samsung SDS is separate from other Samsung 
	#Samsundg Co., Samsung corp., Samsung Electronics, Samsung Mobile etc. They're all just Samsung, proper case
	cn = a_s&.downcase
	if cn&.include? "samsung"
		a_s.gsub(/samsung/i, 'Samsung')
	end
	if ['samsung electronics','samsung mobile'].include? "#{cn}"
		a_s = 'Samsung'
	end
	return a_s
end

def normalize_hewlettpackard(a_s)
	#HP and Hewlett-Packard to HPE
	cn = a_s&.downcase
	if ['hewlett-packard','hewlettpackard','hewlett packard','hp'].include? "#{cn}"
		a_s = 'HPE'
	end
	return a_s
end

def normalize_amazonwebservices(a_s)
	#change Amazon Web Services to AWS
	cn = a_s&.downcase
	if cn&.include? "amazon web services"
		a_s = "AWS"
	end
	return a_s
end

def normalize_soundcloud(a_s)
	#change SoundCloud … to SoundCloud
	cn = a_s&.downcase
	if cn&.include? "soundcloud "
		a_s = "SoundCloud"
	end
	return a_s
end

def normalize_ghostcloud(a_s)
	#change GhostCloud … to SoundCloud
	cn = a_s&.downcase
	if cn&.include? "goundcloud "
		a_s = "GoundCloud"
	end
	return a_s
end

def normalize_possessive(a_s)
	#remove ' if company ends with '
	a_s&.sub!(/'$/, "")
    return a_s
end

suggestions = []
CSV.foreach('developer_affiliation_lookup.csv', headers: true) do |row|
	next if is_comment row
	h = row.to_h
	a_s = h['affiliation_suggestion']
	# add emails with no company as NotFound
	# if company is name associated with email, do Self
	# base on columns: chance, affiliation_suggestion, hashed_email
	if ['high','mid'].include? h['chance']
		a_s = correct_company_name(a_s)
		a_s = check_for_self_employment(a_s)
		a_s = normalize_samsung(a_s)
		a_s = normalize_hewlettpackard(a_s)
		a_s = normalize_amazonwebservices(a_s)
		a_s = normalize_soundcloud(a_s)
		a_s = normalize_ghostcloud(a_s)
		a_s = normalize_possessive(a_s)
		suggestion = [ h['hashed_email'], a_s ]
		#binding.pry
		suggestions.push suggestion
	else #add Unknowns
		suggestion = [ h['hashed_email'], "NotFound" ]
		suggestions.push suggestion
	end
end
puts "found #{suggestions.size} suggestions in developer_affiliation_lookup.csv file"

#now check for existence to decide on update or insertion
ar = ur = 0
text = File.read('cncf-config/email-map')
suggestions.each do |sg|
	#sg[1] can be a company name or Self or NotFound

	#if email found and has something other than self or notfound but new data has something, overwrite
	#if data record is new, add

	ech = "#{sg[0]} #{sg[1]}"
	ect = "#{ech}\n" #new entry based on Clearbit

	if !['Self', 'NotFound'].include? sg[1]
		if !text.include? ect
			# append to end if the email does not already have a company assigment
			short_list = []
			map_list.each do |ml|
				if ml[0] == sg[0]
					short_list.push "#{ml[0]} #{ml[1]}"
				end
			end
			if !short_list.include? ech
				text << ect
				ar += 1
			end
		end
	else
		if (!['Self', 'NotFound'].include? "#{sg[1]}") && (text.include? "#{sg[0]} Self")
			# replace existing Self with a company
			text = text.gsub(/#{sg[0]} Self/, "#{ect}")
			ur += 1
		elsif "#{sg[1]}" == 'Self' && (text.include? "#{sg[0]} NotFound")
			# replace existing NotFound with Self
			text = text.gsub(/#{sg[0]} NotFound/, "#{ect}")
			ur += 1
		end
	end

end

# Write changes back to the file
File.open('cncf-config/email-map', "w") {|file| file.puts text }

puts "altered the email-map file with Clearbit suggestions"
puts "updated #{ur} records}"
puts "added #{ar} records}"

new_array = File.readlines('cncf-config/email-map').sort
File.open('cncf-config/email-map',"w") do |file|
  file.puts new_array
end

puts "sorted email-map"

puts "all done"
