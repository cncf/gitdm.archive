require 'pry'
require 'json'

def merge_github_logins(json_file)
  profs = {}
  data = JSON.parse File.read json_file
  data.each_with_index do |user, i|
    login = user['login']
    profs[login] = [] unless profs.key?(login)
    profs[login] << [user, i]
  end
  mp = {}
  profs.each do |login, profiles|
    mp[login] = profiles if profiles.length > 1
  end
  profs = nil
  mp.each do |login, profiles|
    unknowns = []
    knowns = []
    profiles.each do |profile_data|
      profile, i = *profile_data
      affiliation = profile['affiliation']
      if ['?', 'NotFound', '(Unknown)'].include?(affiliation)
        unknowns << [profile, i]
      else
        knowns << [profile, i]
      end
    end
    if unknowns.length > 0 and knowns.length > 0
      aff = knowns.first[0]['affiliation']
      conflict = false
      knowns.each do |profile_data|
        profile, i = *profile_data
        curr_aff = profile['affiliation']
        unless curr_aff == aff
          email = knowns.first[0]['email']
          curr_email = profile['email']
          STDERR.puts "Affiliations conflict: login: #{login} #{email}:#{aff} != #{curr_email}:#{curr_aff}"
          conflict = true
        end
      end
      next if conflict
      unknowns.each do |profile_data|
        profile, i = *profile_data
        data[i]['affiliation'] = aff
        email = profile['email']
        aff.split(', ').each do |aff_line|
          puts "#{email} #{aff_line}"
        end
      end
    end
  end
  # Write JSON back
  json = JSON.pretty_generate data
  File.write json_file, json
end

if ARGV.size < 1
  puts "Missing argument: JSON_file"
  exit(1)
end

merge_github_logins(ARGV[0])
