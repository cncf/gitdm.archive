require 'json'
require 'pry'

def merge_jsons(primary_json, new_json, email_map)
  data = JSON.parse File.read primary_json
  users = {}
  data.each_with_index do |user, index|
    login = user['login'].downcase
    email = user['email'].downcase
    users[[login, email]] = user
    users[login] = [] unless users.key?(login)
    users[login] << user
  end
  data = JSON.parse File.read new_json
  data.each_with_index do |user, index|
    login = user['login'].downcase
    email = user['email'].downcase
    if users.key?([login, email])
      pri_user = users[[login, email]]
      if user['affiliation'] != pri_user['affiliation'] && pri_user['affiliation'] != '?' && pri_user['affiliation'] != '(Unknown)'
        puts "Using primary affiliation '#{pri_user['affiliation']}' instead of new '#{user['affiliation']}' for #{login}/#{email}"
        user['affiliation'] = pri_user['affiliation']
      end
      if user['sex'] != pri_user['sex'] || user['sex_prob'] != pri_user['sex_prob']
        if (pri_user['sex'] != nil || pri_user['sex_prob'] != nil) && (user['sex'] == nil || user['sex_prob'] == nil)
          puts "Using primary gender '#{pri_user['sex']}, #{pri_user['sex_prob']}' instead of new '#{user['sex']}, #{user['sex_prob']}' for #{login}/#{email}"
          user['sex'] = pri_user['sex']
          user['sex_prob'] = pri_user['sex_prob']
        end
      end
      # if user['country_id'] != pri_user['country_id'] || user['tz'] != pri_user['tz']
      #   binding.pry
      # end
    end
  end
  binding.pry
end

if ARGV.size < 3
  puts "Missing arguments: github_users.old github_users.json cncf-config/email-map"
  exit(1)
end

merge_jsons(ARGV[0], ARGV[1], ARGV[2])
