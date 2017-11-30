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

def correct_company_name(c_n)
	#puts "received #{c_n}"
	#We don't want suffixes like: Co., Ltd., Corp., Inc., Limited., LLC, Group. in names.
	c_n.sub!" GmbH & Co.", ""
	c_n.sub!" S.A.", ""
	c_n.sub!" Co.,", ""
	c_n.sub!" Co.", ""
	c_n.sub!" Co.", ""
	c_n.sub!" Corp.,", ""
	c_n.sub!" Corp.", ""
	c_n.sub!" Corp", ""
	c_n.sub!" GmbH.,", ""
	c_n.sub!" GmbH.", ""
	c_n.sub!" GmbH", ""
	c_n.sub!" Group.,", ""
	c_n.sub!" Group.", ""
	c_n.sub!" Group", ""
	c_n.sub!" Inc.,", ""
	c_n.sub!" Inc.", ""
	c_n.sub!" Inc", ""
	c_n.sub!" Limited.,", ""
	c_n.sub!" Limited.", ""
	c_n.sub!" Limited", ""
	c_n.sub!" LLC.,", ""
	c_n.sub!" LLC.,", ""
	c_n.sub!" LLC.,", ""
	c_n.sub!" Ltd.,", ""
	c_n.sub!" Ltd.", ""
	c_n.sub!" Ltd", ""
	c_n.sub!" LTD,", ""
	c_n.sub!" LTD.,", ""
	c_n.sub!" LTD.,", ""
	c_n.sub!" PLC", ""
	c_n.sub!(/^@/, "")
	#puts "returned #{c_n}"
	#binding.pry
    return c_n
end

def check_for_self_employment(c_n)
	cn = c_n.downcase
	if (cn.include? "learning") || (cn.include? "university") || (cn.include? "institute") then
	   c_n = "Self"
	end
	return c_n
end

def normalize_samsung(c_n)
	#Samsung SDS is separate from other Samsung 
	#Samsundg Co., Samsung corp., Samsung Electronics, Samsung Mobile etc. They're all just Samsung.
	#Also normalize samsung, Samsung, SAMSUNG etc.
	cn = c_n.downcase
	if cn.include? "samsung"
		c_n.gsub(/samsung/i, 'Samsung')
	end
	if c_n.downcase == 'samsung electronics' || c_n.downcase == 'samsung mobile' then
		c_n = 'Samsung'
	end
	return c_n
end

suggestions = []
CSV.foreach('developer_affiliation_lookup.csv', headers: true) do |row|
	next if is_comment row
	h = row.to_h
	# only add emails with companies
	# if company is name associated with email, do Self
	# base on: chance, affiliation_suggestion, hashed_email columns
	if h['chance'] == "high" || h['chance'] == "mid"
		s_c = correct_company_name(h['affiliation_suggestion'])
		s_c = check_for_self_employment(s_c)
		s_c = normalize_samsung(s_c)
		suggestion = [ h['hashed_email'], s_c ]
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

	ec = "#{sg[0]} #{sg[1]}}\n"
	if !['Self', 'NotFound'].include? "#{sg[1]}"
		if ! text.include? "#{ec}"
			# append to end
			text << ec
			ar += 1
		end
	else
		if (text.include? "#{sg[0]} Self") && (!['Self', 'NotFound'].include? "#{sg[1]}")
			# replace existing Self with a company
			text = text.gsub(/#{sg[0]} Self/, "#{ec}")
			ur += 1
		end
		if (text.include? "#{sg[0]} NotFound") && "#{sg[1]}" == 'Self'
			# replace existing NotFound with Self
			text = text.gsub(/#{sg[0]} NotFound/, "#{ec}")
			ur += 1
		end
	end

end

# Write changes back to the file
File.open('cncf-config/email-map', "w") {|file| file.puts text }

puts "altered the email-map file with Clearbit suggestions"
puts "altered #{ur} records}"
puts "added #{ar} records}"

puts "all done"





