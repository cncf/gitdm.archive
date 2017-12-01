# gem install clearbit
# requires ruby 2.3 or above
require 'pry'
require 'csv'
require 'Clearbit'
require 'json'
#Clearbit.key = ENV['CLEARBIT_KEY']
Clearbit.key = 'sk_ab962f5c253faf729edffbe5ec28c23e'
line_num = 0
start_found = false
em_li = []
text = File.open('all.txt').read
text.gsub!(/\r\n?/, "\n")
text.each_line do |line|
  #sl = line.scan(/\d+/)
  sl = line.split
  if sl[0] == 'Developers'
    start_found = true
    next
  end
  if start_found
    if sl[0] == '(Unknown)' || sl[0] == 'NotFound'
      em_li.push sl[1]
      line_num += 1
    else
      break
    end
  end
  #em_li.sort!
end

print "line count #{line_num}\n"

#puts em_li.inspect
chk_cnt = 0

ok_cnt = bad_cnt = err_cnt = 0

CSV.open('developer_affiliation_lookup.csv', 'w') do |csv|
  csv << ["email","chance","affiliation_suggestion","hashed_email","first_name", "last_name", "full_name", "gender", "localization", "bio", "site", "avatar", "employment_name", "employment_domain", "github_handle", "github_company", "github_blog", "linkedin_handle", "googleplus_handle", "aboutme_handle", "gravatar_handle", "aboutme_bio" ]
  em_li.each do |ae|
    if chk_cnt < 1234 #    !!!!!     THIS is the max NUMBER of emails to PROCESS in this BATCH    !!!!!
      em_il = ae.sub('!','@')
      begin
        result = Clearbit::Enrichment.find(email: em_il, stream: true)
          p = result.person
          suggestion = ''
          c = "none"
          pfn = "#{p&.name&.given_name}".downcase
          pln = "#{p&.name&.family_name}".downcase
          #binding.pry
          if !p&.employment&.name.nil? && (p.employment.name == "#{pfn}#{pln}" || p.employment.name == "#{pfn} #{pln}")
            r = "Self"
            chance = "none"
          end
          if !p&.employment&.name.nil? && (p.employment.name.downcase.include? "university") && (p.employment.name.downcase.include? "institute") && (p.employment.name.downcase.include? "academy") && !p&.github&.company.nil? && p.github.company != ""
            r = p.github.company
            chance = "low"
          end
          if !p&.github&.company.nil? && p.github.company != ""
            r = p.github.company
            chance = "mid"
          end
          if !p&.employment&.name.nil? && p.employment.name != "" && p.employment.name != "GitHub"
            r = p.employment.name
            chance = "high"
          end          
          suggestion = r
          csv << ["#{p.email}","#{chance}","#{suggestion}","#{ae}","#{p.name.given_name}","#{p.name.family_name}","#{p.name.fullName}","#{p.gender}","#{p.location}","#{p.bio}","#{p.site}","#{p.avatar}","#{p.employment.name}","#{p.employment.domain}","#{p.github.handle}","#{p.github.company}","#{p.github.blog}","#{p.linkedin.handle}","#{p.googleplus.handle}","#{p.aboutme.handle}","#{p.gravatar.handle}","#{p.aboutme.bio}"]
          ok_cnt += 1
          puts 'got an enrichment'
        rescue StandardError => bang
        hash = JSON[bang]
        hash = JSON.parse(hash)
        if hash.index("email_invalid")
          csv << ["#{ae}","none","","error","invalid", "email", "address"]
          bad_cnt += 1
          puts 'received a bad email msg'
        else
          csv << ["#{ae}","none","","error","bad", "response"]
          puts bang
          err_cnt += 1
        end
      end
    chk_cnt += 1
    end
  end
end
puts "done processing with Clearbit"
puts "count of found: #{ok_cnt}"
puts "count of bad emails: #{bad_cnt}"
puts "count of errored-out: #{err_cnt}"
